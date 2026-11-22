-- Register the distinct sherpa-onnx HTTP provider and bilingual model choices.
DELETE FROM ai_tts_voice WHERE id IN ('TTS_SherpaZipD01', 'TTS_SherpaZip01');
DELETE FROM ai_model_config WHERE id IN ('TTS_SherpaZipDistill', 'TTS_SherpaZip');

INSERT IGNORE INTO ai_model_provider
    (id, model_type, provider_code, name, fields, sort, creator, create_date, updater, update_date)
VALUES
    ('SYSTEM_TTS_SherpaOnnxTTS', 'TTS', 'sherpa_onnx_http', 'Sherpa ONNX 本地语音',
     '[{"key":"model","label":"模型目录","type":"string"},{"key":"url","label":"服务地址","type":"string"},{"key":"voice","label":"默认音色 ID","type":"string"},{"key":"tts_timeout","label":"超时秒数","type":"int"}]',
     26, 1, NOW(), 1, NOW());

INSERT IGNORE INTO ai_model_config
    (id, model_type, model_code, model_name, is_default, is_enabled, config_json, doc_link, sort)
VALUES
    ('TTS_SherpaMelo', 'TTS', 'SherpaOnnxTTS', 'Sherpa Melo 中英', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','model','vits-melo-tts-zh_en','voice','0','url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/pretrained_models/vits.html', 26),
    ('TTS_SherpaMatcha', 'TTS', 'SherpaOnnxTTS', 'Sherpa Matcha 中英', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','model','matcha-icefall-zh-en','voice','0','url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/all/Chinese-English/matcha-icefall-zh-en.html', 27),
    ('TTS_SherpaKokoro10', 'TTS', 'SherpaOnnxTTS', 'Sherpa Kokoro 1.0 中英', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','model','kokoro-multi-lang-v1_0','voice','45','url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/all/Chinese-English/kokoro-multi-lang-v1_0.html', 28),
    ('TTS_SherpaKokoro10Int8', 'TTS', 'SherpaOnnxTTS', 'Sherpa Kokoro 1.0 INT8 中英', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','model','kokoro-int8-multi-lang-v1_0','voice','45','url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/pretrained_models/kokoro.html', 29),
    ('TTS_SherpaKokoro11', 'TTS', 'SherpaOnnxTTS', 'Sherpa Kokoro 1.1 中英', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','model','kokoro-multi-lang-v1_1','voice','3','url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/all/Chinese-English/kokoro-multi-lang-v1_1.html', 30),
    ('TTS_SherpaKokoro11Int8', 'TTS', 'SherpaOnnxTTS', 'Sherpa Kokoro 1.1 INT8 中英', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','model','kokoro-int8-multi-lang-v1_1','voice','3','url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/pretrained_models/kokoro.html', 31),
    ('TTS_SherpaZipDistillInt8', 'TTS', 'SherpaOnnxTTS', 'Sherpa ZipVoice Distill INT8 中英', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','model','sherpa-onnx-zipvoice-distill-int8-zh-en-emilia','voice','0','url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/zipvoice.html', 32),
    ('TTS_SherpaZipDistillFp32', 'TTS', 'SherpaOnnxTTS', 'Sherpa ZipVoice Distill FP32 中英', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','model','sherpa-onnx-zipvoice-distill-fp32-zh-en-emilia','voice','0','url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/zipvoice.html', 33);

INSERT IGNORE INTO ai_tts_voice (id, tts_model_id, name, tts_voice, languages, sort)
VALUES
    ('TTS_SherpaMelo01', 'TTS_SherpaMelo', 'Melo', '0', '中文,English', 1),
    ('TTS_SherpaMatcha01', 'TTS_SherpaMatcha', 'Matcha', '0', '中文,English', 1),
    ('TTS_SherpaKokoro1001', 'TTS_SherpaKokoro10', '晓贝', '45', '中文,English', 1),
    ('TTS_SherpaKokoro1002', 'TTS_SherpaKokoro10', '云剑', '49', '中文,English', 2),
    ('TTS_SherpaKokoro10I01', 'TTS_SherpaKokoro10Int8', '晓贝', '45', '中文,English', 1),
    ('TTS_SherpaKokoro10I02', 'TTS_SherpaKokoro10Int8', '云剑', '49', '中文,English', 2),
    ('TTS_SherpaKokoro1101', 'TTS_SherpaKokoro11', '中文女声 001', '3', '中文,English', 1),
    ('TTS_SherpaKokoro1102', 'TTS_SherpaKokoro11', '中文男声 009', '58', '中文,English', 2),
    ('TTS_SherpaKokoro11I01', 'TTS_SherpaKokoro11Int8', '中文女声 001', '3', '中文,English', 1),
    ('TTS_SherpaKokoro11I02', 'TTS_SherpaKokoro11Int8', '中文男声 009', '58', '中文,English', 2),
    ('TTS_SherpaZipDI01', 'TTS_SherpaZipDistillInt8', '雷军示例音色', '0', '中文,English', 1),
    ('TTS_SherpaZipDF01', 'TTS_SherpaZipDistillFp32', '雷军示例音色', '0', '中文,English', 1);
