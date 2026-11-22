"""Lazy, single-model sherpa-onnx TTS service for Xiaozhi."""

import io
import logging
import multiprocessing as mp
import threading
import time
import wave
from pathlib import Path

from flask import Flask, Response, jsonify, request


ROOT = Path("/models")
MODEL_KINDS = {
    "vits-melo-tts-zh_en": "vits",
    "matcha-icefall-zh-en": "matcha",
    "kokoro-multi-lang-v1_1": "kokoro",
}
IDLE_SECONDS = 120
app = Flask(__name__)
ctx = mp.get_context("spawn")
lock = threading.Lock()
worker = None
pipe = None
loaded_model = None
last_used = 0.0


def one_file(directory, pattern):
    matches = sorted(p for p in directory.glob(pattern) if p.stat().st_size > 1024 * 1024)
    if len(matches) != 1:
        raise ValueError(f"Expected one {pattern} in {directory}, found {len(matches)}")
    return str(matches[0])


def rule_fsts(directory):
    return ",".join(str(directory / name) for name in
                    ("phone-zh.fst", "date-zh.fst", "number-zh.fst",
                     "phone.fst", "date.fst", "number.fst")
                    if (directory / name).is_file())


def make_tts(name):
    import sherpa_onnx

    directory = ROOT / name
    kind = MODEL_KINDS[name]
    if not directory.is_dir():
        raise FileNotFoundError(f"Model is not downloaded: {name}")
    config_kwargs = {"num_threads": 2, "provider": "cpu", "debug": False}
    if kind == "vits":
        config_kwargs["vits"] = sherpa_onnx.OfflineTtsVitsModelConfig(
            model=str(directory / "model.onnx"),
            lexicon=str(directory / "lexicon.txt"),
            tokens=str(directory / "tokens.txt"),
            data_dir=str(directory / "espeak-ng-data") if (directory / "espeak-ng-data").is_dir() else "",
        )
    elif kind == "matcha":
        config_kwargs["matcha"] = sherpa_onnx.OfflineTtsMatchaModelConfig(
            acoustic_model=one_file(directory, "model-steps-*.onnx"),
            vocoder=str(ROOT / "vocos-16khz-univ.onnx"),
            lexicon=str(directory / "lexicon.txt"),
            tokens=str(directory / "tokens.txt"),
            data_dir=str(directory / "espeak-ng-data"),
        )
    else:
        config_kwargs["kokoro"] = sherpa_onnx.OfflineTtsKokoroModelConfig(
            model=one_file(directory, "model*.onnx"),
            voices=str(directory / "voices.bin"),
            tokens=str(directory / "tokens.txt"),
            lexicon=",".join(str(directory / f) for f in
                             ("lexicon-us-en.txt", "lexicon-zh.txt")),
            data_dir=str(directory / "espeak-ng-data"),
        )
    config = sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(**config_kwargs),
        rule_fsts=rule_fsts(directory),
        max_num_sentences=1,
    )
    if not config.validate():
        raise ValueError(f"Invalid sherpa-onnx configuration for {name}")
    return sherpa_onnx.OfflineTts(config)


def run_worker(connection, name):
    try:
        import numpy as np
        import sherpa_onnx

        tts = make_tts(name)
        connection.send(("ready", None))
        while True:
            text, sid = connection.recv()
            gen = sherpa_onnx.GenerationConfig()
            gen.sid = sid
            gen.speed = 1.0
            audio = tts.generate(text, gen)
            if len(audio.samples) == 0:
                raise RuntimeError("Sherpa returned empty audio")
            samples = (np.clip(audio.samples, -1, 1) * 32767).astype("<i2")
            out = io.BytesIO()
            with wave.open(out, "wb") as wav:
                wav.setnchannels(1)
                wav.setsampwidth(2)
                wav.setframerate(audio.sample_rate)
                wav.writeframes(samples.tobytes())
            connection.send(("audio", out.getvalue()))
    except EOFError:
        pass
    except Exception as exc:
        logging.exception("Sherpa worker failed for %s", name)
        try:
            connection.send(("error", str(exc)))
        except (BrokenPipeError, EOFError):
            pass
    finally:
        connection.close()


def stop_worker():
    global worker, pipe, loaded_model
    if worker is not None:
        worker.terminate()
        worker.join(timeout=5)
        if worker.is_alive():
            worker.kill()
            worker.join(timeout=5)
    if pipe is not None:
        pipe.close()
    worker = pipe = loaded_model = None


def start_worker(name):
    global worker, pipe, loaded_model
    stop_worker()
    parent, child = ctx.Pipe()
    process = ctx.Process(target=run_worker, args=(child, name), daemon=True)
    process.start()
    child.close()
    if not parent.poll(90):
        process.terminate()
        process.join(timeout=5)
        parent.close()
        raise TimeoutError(f"Loading {name} timed out")
    status, detail = parent.recv()
    if status != "ready":
        process.join(timeout=5)
        parent.close()
        raise RuntimeError(detail)
    worker, pipe, loaded_model = process, parent, name
    logging.info("Loaded Sherpa model %s", name)


def unload_idle():
    while True:
        time.sleep(10)
        with lock:
            if worker is not None and time.monotonic() - last_used > IDLE_SECONDS:
                logging.info("Unloading idle Sherpa model %s", loaded_model)
                stop_worker()


@app.get("/info")
def info():
    return jsonify({"loaded_model": loaded_model, "available_models": sorted(MODEL_KINDS)})


@app.post("/synthesize")
def synthesize():
    global last_used
    data = request.get_json(silent=True) or {}
    name = data.get("model", "")
    text = data.get("text", "").strip()
    try:
        sid = int(data.get("speaker_id", 0))
    except (ValueError, TypeError):
        return jsonify({"error": "speaker_id must be an integer"}), 400
    if name not in MODEL_KINDS or not text or sid < 0:
        return jsonify({"error": "A valid model, text, and speaker_id are required"}), 400
    with lock:
        try:
            if loaded_model != name or worker is None or not worker.is_alive():
                start_worker(name)
            pipe.send((text, sid))
            if not pipe.poll(180):
                stop_worker()
                raise TimeoutError("Sherpa synthesis timed out")
            status, result = pipe.recv()
            last_used = time.monotonic()
            if status != "audio":
                stop_worker()
                raise RuntimeError(result)
            return Response(result, mimetype="audio/wav")
        except (EOFError, OSError, RuntimeError, TimeoutError, ValueError) as exc:
            logging.exception("Synthesis failed for %s", name)
            stop_worker()
            return jsonify({"error": str(exc)}), 503


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    threading.Thread(target=unload_idle, daemon=True).start()
    app.run(host="0.0.0.0", port=5000, threaded=True)
