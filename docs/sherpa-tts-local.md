# 本地 Sherpa ONNX TTS

智控台中的 **Sherpa ONNX 本地语音** 是一个独立于 Piper 的 TTS 选项。它的音色列表只保留四项：Melo 中英、Matcha 中英、Kokoro 1.1 女001、Kokoro 1.1 男009。Piper 的三个音色仍在 **Piper local Chinese** 中选择。

服务启动时不加载 TTS 模型。首次使用某个模型时加载，切换模型时结束旧工作进程，空闲 120 秒后也自动卸载。Piper 同样只保留当前使用的一个音色，并在空闲 120 秒后卸载。模型文件保存在磁盘，不进入 Git 仓库或服务端镜像。

部署时在仓库根目录执行：

```sh
sh download-sherpa-tts-models.sh
cd main/xiaozhi-server
docker compose -f docker-compose_all.yml -f docker-compose.fork.yml --profile local-tts up -d --build sherpa-tts piper-tts xiaozhi-esp32-server
```

然后将 `register-sherpa-tts.sql` 导入部署用的 `xiaozhi_esp32_server` 数据库。升级已有部署时，先导入 SQL，再重建 `sherpa-tts` 服务，避免正在使用的旧音色突然失效。SQL 开头设置 `utf8mb4` 连接字符集，会修复早期导入产生的中文乱码，并把原先八个独立的 Sherpa TTS 选项合并为一个。旧 Kokoro 女声和男声分别迁至保留的 1.1 女声和男声；其他被删除的音色迁至 Melo。再次执行不会覆盖仍被保留的智能体音色选择。

如果是在旧部署上重新导入 SQL，还要清除 Redis 中音色详情的旧缓存，然后重启主服务，使已连接的客户端重新读取配置：

```sh
docker exec xiaozhi-esp32-server-redis sh -c 'redis-cli --scan --pattern "*:TTS_Sherpa*" | xargs -r redis-cli DEL'
docker restart xiaozhi-esp32-server
```

## 模型说明

| 架构 | 可选模型 | 说明 |
| --- | --- | --- |
| VITS/Melo | `vits-melo-tts-zh_en` | 单音色；英文词发音受内置词典限制 |
| Matcha | `matcha-icefall-zh-en` | 单音色，额外使用 16 kHz Vocos 声码器 |
| Kokoro 1.1 | `kokoro-multi-lang-v1_1` | 女001 和男009 共用同一个模型文件，按 speaker ID 选择 |

模型来源：[sherpa-onnx TTS 发布页](https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models)。Kokoro 的全部 speaker ID 未加入智控台音色列表。
