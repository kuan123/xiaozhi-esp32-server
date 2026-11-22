# 本地中文 TTS：Piper

这套部署通过 Piper 的 HTTP 服务和现有的 `CustomTTS` 适配器连接。Piper 在服务器 CPU 上生成 WAV，服务只在 Docker 内部网络开放，不映射宿主机端口。

## 模型文件

下载以下两个文件到 `main/xiaozhi-server/models/piper/`（模型文件不提交到 Git）：

- `https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/zh/zh_CN/huayan/medium/zh_CN-huayan-medium.onnx`
- `https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/zh/zh_CN/huayan/medium/zh_CN-huayan-medium.onnx.json`

该音色的模型卡标明训练数据授权状态为 Unknown；如需商用，先核实音色授权。

## 启动

在 `main/xiaozhi-server` 目录运行：

```sh
docker compose -f docker-compose_all.yml -f docker-compose.fork.yml --profile local-tts up -d --build piper-tts
```

执行 `register-piper-tts.sql` 注册可选的 TTS 模型与音色，或者在智控台新增 TTS 模型并将模型代码选为 `CustomTTS`，配置：

```json
{
  "type": "custom",
  "method": "POST",
  "url": "http://piper-tts:5000/synthesize",
  "params": {"text": "{prompt_text}"},
  "headers": {},
  "format": "wav",
  "output_dir": "tmp/",
  "tts_timeout": 15
}
```

然后在智能体上选用该模型和音色。Piper 这个中文模型只有一个音色；`tts_voice` 字段留空即可。将智能体 TTS 模型改回原先模型即可回退，Piper 容器不影响其他服务。

Piper HTTP 接口文档：https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/API_HTTP.md
