class_name Speech
extends RefCounted
## Text-to-speech wrapper (PLAN.md: calm, slightly slower voice). Swappable for recorded audio later.
## Does nothing when TTS is off in project settings, no voice is found, or running headless (tests/CI).
##
## NEVER interrupts the voice. On Windows with Godot 4.7.2, stopping speech mid-sentence
## (tts_stop() or tts_speak(..., interrupt=true)) can hang or crash the game — that was the
## Playtest 1 freeze (see DECISIONS.md). Instead, a line asked for while the voice is busy waits
## and is spoken as soon as it's quiet; only the newest waiting line is kept.
## GameState calls poll() a few times a second to speak the waiting line.

const LANGUAGE: String = "en"
const RATE: float = 0.9
const PITCH: float = 1.0
const VOLUME: int = 50

static var _voice: String = ""
static var _looked_up: bool = false
## The line waiting for the voice to be free: {"text", "rate", "pitch"}, or {}.
static var _pending: Dictionary = {}
## Tests swap these for fakes; by default they talk to DisplayServer.
static var is_speaking_fn: Callable = _real_is_speaking
static var speak_fn: Callable = _real_speak
## Tests set this to use the fakes without a real voice.
static var force_available: bool = false


static func is_available() -> bool:
	return force_available or voice() != ""


static func voice() -> String:
	if not _looked_up:
		_looked_up = true
		if DisplayServer.get_name() != "headless" and ProjectSettings.get_setting("audio/general/text_to_speech", false):
			var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(LANGUAGE)
			if not voices.is_empty():
				_voice = voices[0]
	return _voice


## Says `text` now if the voice is free, otherwise as soon as it's quiet (replacing any older waiting line).
static func say(text: String, rate: float = RATE, pitch: float = PITCH) -> void:
	if not is_available() or text == "":
		return
	if is_speaking_fn.call():
		_pending = {"text": text, "rate": rate, "pitch": pitch}
		GameState.breadcrumb("tts: waiting to say '%s'" % text.left(40))
		return
	_pending = {}
	_speak_now(text, rate, pitch)


## Speaks the waiting line once the voice is quiet. Call regularly (GameState does).
static func poll() -> void:
	if _pending.is_empty() or not is_available():
		return
	if is_speaking_fn.call():
		return
	var line: Dictionary = _pending
	_pending = {}
	_speak_now(str(line["text"]), float(line["rate"]), float(line["pitch"]))


## Drops the waiting line. The current sentence finishes on its own (it's never cut off — see above).
static func stop() -> void:
	_pending = {}


static func pending_text() -> String:
	return str(_pending.get("text", ""))


## Puts the real DisplayServer voice back (after tests used fakes).
static func use_real_voice() -> void:
	is_speaking_fn = _real_is_speaking
	speak_fn = _real_speak
	force_available = false
	_pending = {}


static func _speak_now(text: String, rate: float, pitch: float) -> void:
	GameState.breadcrumb("tts: speak '%s'" % text.left(40))
	speak_fn.call(text, voice(), rate, pitch)
	GameState.breadcrumb("tts: queued")


static func _real_is_speaking() -> bool:
	return DisplayServer.tts_is_speaking()


static func _real_speak(text: String, voice_id: String, rate: float, pitch: float) -> void:
	DisplayServer.tts_speak(text, voice_id, VOLUME, pitch, rate)
