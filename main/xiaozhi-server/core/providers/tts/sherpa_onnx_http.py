"""Sherpa ONNX sidecar provider. Model loading happens in the sidecar on demand."""

from core.providers.tts.custom import TTSProvider as CustomTTSProvider


class TTSProvider(CustomTTSProvider):
    def __init__(self, config, delete_audio_file):
        configured = config.copy()
        selected = str(configured.get("private_voice") or configured.get("voice", ""))
        model, separator, speaker_id = selected.partition("|")
        if not separator:
            model, speaker_id = configured.get("model"), selected
        if not model or not speaker_id.isdecimal():
            raise ValueError("Sherpa TTS voice must be model|speaker_id")
        configured.setdefault("url", "http://sherpa-tts:5000/synthesize")
        configured["method"] = "POST"
        configured["format"] = "wav"
        configured["params"] = {
            "text": "{prompt_text}",
            "model": model,
            "speaker_id": "{voice}",
        }
        configured.pop("private_voice", None)
        configured["voice"] = speaker_id
        super().__init__(configured, delete_audio_file)
