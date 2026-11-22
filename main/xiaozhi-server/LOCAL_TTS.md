# 本地中文 TTS：Piper

这套部署通过 Piper 的 HTTP 服务和现有的 `CustomTTS` 适配器连接。Piper 在服务器 CPU 上生成 WAV，服务只在 Docker 内部网络开放，不映射宿主机端口。

## 模型文件

下载以下模型和配置文件到 `main/xiaozhi-server/models/piper/`（模型文件不提交到 Git）：

- `https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/zh/zh_CN/huayan/medium/zh_CN-huayan-medium.onnx`
- `https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/zh/zh_CN/huayan/medium/zh_CN-huayan-medium.onnx.json`
- `https://huggingface.co/rhasspy/piper-voices/resolve/main/zh/zh_CN/chaowen/medium/zh_CN-chaowen-medium.onnx`
- `https://huggingface.co/rhasspy/piper-voices/resolve/main/zh/zh_CN/chaowen/medium/zh_CN-chaowen-medium.onnx.json`
- `https://huggingface.co/rhasspy/piper-voices/resolve/main/zh/zh_CN/xiao_ya/medium/zh_CN-xiao_ya-medium.onnx`
- `https://huggingface.co/rhasspy/piper-voices/resolve/main/zh/zh_CN/xiao_ya/medium/zh_CN-xiao_ya-medium.onnx.json`

Chaowen 和 Xiao Ya 还需要中文拼音转换资源。下载 `https://huggingface.co/datasets/rhasspy/piper-checkpoints/resolve/main/zh/zh_CN/_resources/g2pw.tar.gz`，解压到 `models/piper/g2pW/`，确保其中有 `g2pw.onnx` 等文件。这个目录也不提交到 Git。

镜像构建时会缓存 `bert-base-chinese` 分词器；运行时设置为离线模式，因此语音合成不依赖外网。

Huayan 的模型卡标明训练数据授权状态为 Unknown；Xiao Ya 标明仅限非商用。各音色的授权应分别核实。

## 启动

在 `main/xiaozhi-server` 目录运行：

```sh
docker compose -f docker-compose_all.yml -f docker-compose.fork.yml --profile local-tts up -d --build piper-tts
```

执行 `register-piper-tts.sql` 注册可选的 TTS 模型与音色，或者在智控台新增 TTS 模型并将模型代码选为 `CustomTTS`，配置：

如果是从单音色版本升级，SQL 更新后清除旧的模型配置缓存，否则智控台可能已经选了新音色，服务端仍按旧配置调用默认音色：

```sh
docker exec xiaozhi-esp32-server-redis redis-cli DEL model:data:TTS_PiperLocal
```

```json
{
  "type": "custom",
  "method": "POST",
  "url": "http://piper-tts:5000/synthesize",
  "params": {"text": "{prompt_text}", "voice": "{voice}"},
  "voice": "zh_CN-huayan-medium",
  "headers": {},
  "format": "wav",
  "output_dir": "tmp/",
  "tts_timeout": 15
}
```

然后在智能体上选用该模型和 Huayan、Chaowen、Xiao Ya 三个音色之一。`CustomTTS` 会把所选音色代码填入 `{voice}`。将智能体 TTS 模型改回原先模型即可回退，Piper 容器不影响其他服务。

Piper HTTP 接口文档：https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/API_HTTP.md
