"""Sherpa ONNX sidecar provider. Model loading happens in the sidecar on demand."""

from core.providers.tts.custom import TTSProvider as CustomTTSProvider


class TTSProvider(CustomTTSProvider):
    def __init__(self, config, delete_audio_file):
        configured = config.copy()
        model = configured.get("model")
        if not model:
            raise ValueError("Sherpa TTS model is required")
        configured.setdefault("url", "http://sherpa-tts:5000/synthesize")
        configured["method"] = "POST"
        configured["format"] = "wav"
        configured["params"] = {
            "text": "{prompt_text}",
            "model": model,
            "speaker_id": "{voice}",
        }
        configured["voice"] = str(configured.get("private_voice") or configured.get("voice", "0"))
        super().__init__(configured, delete_audio_file)
