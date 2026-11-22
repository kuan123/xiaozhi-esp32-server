-- One Sherpa TTS model with model and speaker selected through its voice list.
-- SET NAMES also repairs installations that previously imported UTF-8 through latin1.
SET NAMES utf8mb4;

INSERT INTO ai_model_provider
    (id, model_type, provider_code, name, fields, sort, creator, create_date, updater, update_date)
VALUES
    ('SYSTEM_TTS_SherpaOnnxTTS', 'TTS', 'sherpa_onnx_http', 'Sherpa ONNX 本地语音',
     '[{"key":"url","label":"服务地址","type":"string"},{"key":"voice","label":"默认音色","type":"string"},{"key":"tts_timeout","label":"超时秒数","type":"int"}]',
     26, 1, NOW(), 1, NOW())
ON DUPLICATE KEY UPDATE name=VALUES(name), fields=VALUES(fields);

INSERT IGNORE INTO ai_model_config
    (id, model_type, model_code, model_name, is_default, is_enabled, config_json, doc_link, sort)
VALUES
    ('TTS_SherpaLocal', 'TTS', 'SherpaOnnxTTS', 'Sherpa ONNX 本地语音', 0, 1,
     JSON_OBJECT('type','sherpa_onnx_http','voice','vits-melo-tts-zh_en|0',
                 'url','http://sherpa-tts:5000/synthesize','output_dir','tmp/','tts_timeout',180),
     'https://k2-fsa.github.io/sherpa/onnx/tts/all/', 26);
UPDATE ai_model_config SET model_name='Sherpa ONNX 本地语音' WHERE id='TTS_SherpaLocal';

INSERT INTO ai_tts_voice (id, tts_model_id, name, tts_voice, languages, sort)
VALUES
    ('TTS_SherpaMelo01', 'TTS_SherpaLocal', 'Melo 中英', 'vits-melo-tts-zh_en|0', '中文,English', 1),
    ('TTS_SherpaMatcha01', 'TTS_SherpaLocal', 'Matcha 中英', 'matcha-icefall-zh-en|0', '中文,English', 2),
    ('TTS_SherpaKokoro1101', 'TTS_SherpaLocal', 'Kokoro 1.1 女001', 'kokoro-multi-lang-v1_1|3', '中文,English', 3),
    ('TTS_SherpaKokoro1102', 'TTS_SherpaLocal', 'Kokoro 1.1 男009', 'kokoro-multi-lang-v1_1|58', '中文,English', 4)
ON DUPLICATE KEY UPDATE tts_model_id=VALUES(tts_model_id), name=VALUES(name),
                        tts_voice=VALUES(tts_voice), languages=VALUES(languages), sort=VALUES(sort);

-- Keep existing agent and template voice IDs while changing the model ID.
UPDATE ai_agent SET tts_model_id='TTS_SherpaLocal'
WHERE tts_model_id IN ('TTS_SherpaMelo','TTS_SherpaMatcha','TTS_SherpaKokoro10',
                       'TTS_SherpaKokoro10Int8','TTS_SherpaKokoro11','TTS_SherpaKokoro11Int8',
                       'TTS_SherpaZipDistillInt8','TTS_SherpaZipDistillFp32',
                       'TTS_SherpaZipDistill','TTS_SherpaZip');
UPDATE ai_agent_template SET tts_model_id='TTS_SherpaLocal'
WHERE tts_model_id IN ('TTS_SherpaMelo','TTS_SherpaMatcha','TTS_SherpaKokoro10',
                       'TTS_SherpaKokoro10Int8','TTS_SherpaKokoro11','TTS_SherpaKokoro11Int8',
                       'TTS_SherpaZipDistillInt8','TTS_SherpaZipDistillFp32',
                       'TTS_SherpaZipDistill','TTS_SherpaZip');

-- Keep the matching gender when retiring Kokoro 1.0 and quantized voices.
UPDATE ai_agent SET tts_voice_id=CASE tts_voice_id
    WHEN 'TTS_SherpaKokoro1001' THEN 'TTS_SherpaKokoro1101'
    WHEN 'TTS_SherpaKokoro10I01' THEN 'TTS_SherpaKokoro1101'
    WHEN 'TTS_SherpaKokoro11I01' THEN 'TTS_SherpaKokoro1101'
    WHEN 'TTS_SherpaKokoro1002' THEN 'TTS_SherpaKokoro1102'
    WHEN 'TTS_SherpaKokoro10I02' THEN 'TTS_SherpaKokoro1102'
    WHEN 'TTS_SherpaKokoro11I02' THEN 'TTS_SherpaKokoro1102'
    ELSE 'TTS_SherpaMelo01' END
WHERE tts_model_id='TTS_SherpaLocal'
  AND (tts_voice_id IS NULL OR tts_voice_id NOT IN
       ('TTS_SherpaMelo01','TTS_SherpaMatcha01','TTS_SherpaKokoro1101','TTS_SherpaKokoro1102'));
UPDATE ai_agent_template SET tts_voice_id=CASE tts_voice_id
    WHEN 'TTS_SherpaKokoro1001' THEN 'TTS_SherpaKokoro1101'
    WHEN 'TTS_SherpaKokoro10I01' THEN 'TTS_SherpaKokoro1101'
    WHEN 'TTS_SherpaKokoro11I01' THEN 'TTS_SherpaKokoro1101'
    WHEN 'TTS_SherpaKokoro1002' THEN 'TTS_SherpaKokoro1102'
    WHEN 'TTS_SherpaKokoro10I02' THEN 'TTS_SherpaKokoro1102'
    WHEN 'TTS_SherpaKokoro11I02' THEN 'TTS_SherpaKokoro1102'
    ELSE 'TTS_SherpaMelo01' END
WHERE tts_model_id='TTS_SherpaLocal'
  AND (tts_voice_id IS NULL OR tts_voice_id NOT IN
       ('TTS_SherpaMelo01','TTS_SherpaMatcha01','TTS_SherpaKokoro1101','TTS_SherpaKokoro1102'));

DELETE FROM ai_tts_voice WHERE id LIKE 'TTS_Sherpa%'
  AND id NOT IN ('TTS_SherpaMelo01','TTS_SherpaMatcha01',
                 'TTS_SherpaKokoro1101','TTS_SherpaKokoro1102');
DELETE FROM ai_model_config WHERE id IN (
    'TTS_SherpaMelo','TTS_SherpaMatcha','TTS_SherpaKokoro10',
    'TTS_SherpaKokoro10Int8','TTS_SherpaKokoro11','TTS_SherpaKokoro11Int8',
    'TTS_SherpaZipDistillInt8','TTS_SherpaZipDistillFp32',
    'TTS_SherpaZipDistill','TTS_SherpaZip');
