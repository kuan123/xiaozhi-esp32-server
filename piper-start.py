import json
import signal
import subprocess
import time
from urllib.request import Request, urlopen


VOICES = (
    "zh_CN-huayan-medium",
    "zh_CN-chaowen-medium",
    "zh_CN-xiao_ya-medium",
)
URL = "http://127.0.0.1:5000/synthesize"

server = subprocess.Popen(
    [
        "python", "-m", "piper.http_server",
        "-m", VOICES[0],
        "--data-dir", "/models",
        "--host", "0.0.0.0",
        "--port", "5000",
    ]
)


def stop(_signum, _frame):
    server.terminate()
    raise SystemExit(0)


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

try:
    for _ in range(60):
        if server.poll() is not None:
            raise RuntimeError("Piper HTTP server exited during startup")
        try:
            with urlopen("http://127.0.0.1:5000/info", timeout=1):
                break
        except OSError:
            time.sleep(1)
    else:
        raise TimeoutError("Piper HTTP server did not become ready")

    for voice in VOICES:
        payload = json.dumps({"text": "你好。", "voice": voice}).encode("utf-8")
        request = Request(URL, data=payload, headers={"Content-Type": "application/json"})
        with urlopen(request, timeout=90) as response:
            if response.read(4) != b"RIFF":
                raise ValueError(f"Piper returned invalid WAV for {voice}")
        print(f"Warmed Piper voice: {voice}", flush=True)

    raise SystemExit(server.wait())
finally:
    if server.poll() is None:
        server.terminate()
        server.wait(timeout=10)
