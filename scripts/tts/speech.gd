class_name Speech
extends RefCounted
## Text-to-speech wrapper (PLAN.md: calm, slightly slower voice). Swappable for recorded audio later.
## Does nothing when TTS is off in project settings, no voice is found, or running headless (tests/CI).

const LANGUAGE: String = "en"
const RATE: float = 0.9
const PITCH: float = 1.0

static var _voice: String = ""
static var _looked_up: bool = false


static func is_available() -> bool:
	return voice() != ""


static func voice() -> String:
	if not _looked_up:
		_looked_up = true
		if DisplayServer.get_name() != "headless" and ProjectSettings.get_setting("audio/general/text_to_speech", false):
			var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(LANGUAGE)
			if not voices.is_empty():
				_voice = voices[0]
	return _voice


## Stops anything already speaking, then says `text`.
static func say(text: String, rate: float = RATE, pitch: float = PITCH) -> void:
	if not is_available() or text == "":
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voice(), 50, pitch, rate)


static func stop() -> void:
	if is_available():
		DisplayServer.tts_stop()
