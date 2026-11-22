# 本地 Sherpa ONNX TTS

智控台中的 **Sherpa ONNX 本地语音** 是独立于 Piper 的 TTS 类型。可选择 Melo、Matcha、Kokoro 1.0/1.1 和 ZipVoice 中英双语模型；Kokoro 和 ZipVoice 的量化版本也单独列出，方便比较音质、速度和内存。Piper 的三个音色仍在 **Piper local Chinese** 中选择。

服务启动时不加载 TTS 模型。首次使用某个模型时加载，切换模型时结束旧工作进程，空闲 120 秒后也自动卸载。Piper 同样只保留当前使用的一个音色，并在空闲 120 秒后卸载。模型文件保存在磁盘，不进入 Git 仓库或服务端镜像。

部署时在仓库根目录执行：

```sh
sh download-sherpa-tts-models.sh
cd main/xiaozhi-server
docker compose -f docker-compose_all.yml -f docker-compose.fork.yml --profile local-tts up -d --build sherpa-tts piper-tts xiaozhi-esp32-server
```

然后将 `register-sherpa-tts.sql` 导入部署用的 `xiaozhi_esp32_server` 数据库。该 SQL 使用 `INSERT IGNORE`，再次执行不会覆盖智控台中的用户设置。

## 模型说明

| 架构 | 可选模型 | 说明 |
| --- | --- | --- |
| VITS/Melo | `vits-melo-tts-zh_en` | 单音色；英文词发音受内置词典限制 |
| Matcha | `matcha-icefall-zh-en` | 单音色，额外使用 16 kHz Vocos 声码器 |
| Kokoro | `kokoro-multi-lang-v1_0`、`kokoro-multi-lang-v1_1` | 分别提供代表性的中文女声和男声 |
| Kokoro INT8 | `kokoro-int8-multi-lang-v1_0`、`kokoro-int8-multi-lang-v1_1` | 量化模型，使用更少内存 |
| ZipVoice Distill 变体 | `sherpa-onnx-zipvoice-distill-int8-zh-en-emilia`、`sherpa-onnx-zipvoice-distill-fp32-zh-en-emilia` | 便于比较 INT8 量化和 FP32 标准精度 |

模型来源：[sherpa-onnx TTS 发布页](https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models)。[ZipVoice 官方说明](https://k2-fsa.github.io/sherpa/onnx/tts/zipvoice.html)要求参考音频和完全对应的参考文本，当前服务使用发布包的示例素材；若需自定义音色，需要同时替换这两项。此处登记的是**模型**及少量代表音色，Kokoro 的全部 speaker ID 尚未加入智控台音色列表。
