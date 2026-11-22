"""Single-voice, on-demand Piper HTTP service for the local Xiaozhi server."""

import gc
import io
import logging
import threading
import time
import wave
from ctypes import CDLL
from pathlib import Path

from flask import Flask, Response, jsonify, request
from piper import PiperVoice


MODELS = Path("/models")
VOICES = {
    "zh_CN-huayan-medium",
    "zh_CN-chaowen-medium",
    "zh_CN-xiao_ya-medium",
}
app = Flask(__name__)
lock = threading.Lock()
loaded_name = None
loaded_voice = None
last_used = 0.0
IDLE_SECONDS = 120
libc = CDLL("libc.so.6")


def release_memory():
    gc.collect()
    libc.malloc_trim(0)


def unload_idle():
    global loaded_name, loaded_voice
    while True:
        time.sleep(10)
        with lock:
            if loaded_voice is not None and time.monotonic() - last_used > IDLE_SECONDS:
                logging.info("Unloading idle Piper voice %s", loaded_name)
                loaded_voice = None
                loaded_name = None
                release_memory()


@app.get("/info")
def info():
    return jsonify({"loaded_voice": loaded_name, "available_voices": sorted(VOICES)})


@app.post("/synthesize")
def synthesize():
    global loaded_name, loaded_voice, last_used
    data = request.get_json(silent=True) or {}
    name = data.get("voice", "zh_CN-huayan-medium")
    text = data.get("text", "").strip()
    if name not in VOICES or not text:
        return jsonify({"error": "A valid voice and nonempty text are required"}), 400

    with lock:
        if name != loaded_name:
            model_path = MODELS / f"{name}.onnx"
            if not model_path.is_file():
                return jsonify({"error": f"Model is missing: {name}"}), 503
            loaded_voice = None
            loaded_name = None
            release_memory()
            logging.info("Loading Piper voice %s", name)
            loaded_voice = PiperVoice.load(model_path)
            loaded_name = name

        out = io.BytesIO()
        with wave.open(out, "wb") as wav_file:
            loaded_voice.synthesize_wav(text, wav_file)
        last_used = time.monotonic()
        return Response(out.getvalue(), mimetype="audio/wav")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    threading.Thread(target=unload_idle, daemon=True).start()
    app.run(host="0.0.0.0", port=5000, threaded=True)
