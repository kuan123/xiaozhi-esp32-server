INSERT IGNORE INTO ai_model_config
    (id, model_type, model_code, model_name, is_default, is_enabled, config_json, sort)
VALUES
    ('TTS_PiperLocal', 'TTS', 'CustomTTS', 'Piper local Chinese', 0, 1,
     JSON_OBJECT(
         'type', 'custom',
         'method', 'POST',
         'url', 'http://piper-tts:5000/synthesize',
         'params', JSON_OBJECT('text', '{prompt_text}', 'voice', '{voice}'),
         'voice', 'zh_CN-huayan-medium',
         'headers', JSON_OBJECT(),
         'format', 'wav',
         'output_dir', 'tmp/',
         'tts_timeout', 15
     ), 25);

UPDATE ai_model_config
SET config_json = JSON_SET(config_json,
    '$.params.voice', '{voice}',
    '$.voice', 'zh_CN-huayan-medium')
WHERE id = 'TTS_PiperLocal';

INSERT IGNORE INTO ai_tts_voice
    (id, tts_model_id, name, tts_voice, languages, sort)
VALUES
    ('TTS_PiperLocal0001', 'TTS_PiperLocal', 'Huayan', 'zh_CN-huayan-medium', 'Mandarin', 1),
    ('TTS_PiperLocal0002', 'TTS_PiperLocal', 'Chaowen', 'zh_CN-chaowen-medium', 'Mandarin', 2),
    ('TTS_PiperLocal0003', 'TTS_PiperLocal', 'Xiao Ya', 'zh_CN-xiao_ya-medium', 'Mandarin', 3);

UPDATE ai_tts_voice
SET tts_voice = 'zh_CN-huayan-medium'
WHERE id = 'TTS_PiperLocal0001';
