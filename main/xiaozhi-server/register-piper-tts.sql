INSERT IGNORE INTO ai_model_config
    (id, model_type, model_code, model_name, is_default, is_enabled, config_json, sort)
VALUES
    ('TTS_PiperLocal', 'TTS', 'CustomTTS', 'Piper local Chinese', 0, 1,
     JSON_OBJECT(
         'type', 'custom',
         'method', 'POST',
         'url', 'http://piper-tts:5000/synthesize',
         'params', JSON_OBJECT('text', '{prompt_text}'),
         'headers', JSON_OBJECT(),
         'format', 'wav',
         'output_dir', 'tmp/',
         'tts_timeout', 15
     ), 25);

INSERT IGNORE INTO ai_tts_voice
    (id, tts_model_id, name, tts_voice, languages, sort)
VALUES
    ('TTS_PiperLocal0001', 'TTS_PiperLocal', 'Huayan', '', 'Mandarin', 1);
