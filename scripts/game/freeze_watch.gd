class_name FreezeWatch
extends Node
## Playtest freeze detector. The game leaves "breadcrumbs" (short notes like "tts: speaking")
## as it works. A background thread checks that the main loop keeps ticking; if it stops for
## `stall_ms`, the thread writes a "freeze" event with the most recent breadcrumbs to the
## playtest log, so we can see exactly which step hung. If the game wakes up again it writes
## "recovered" with how long it was stuck.

const DEFAULT_STALL_MS: int = 5000
const CHECK_EVERY_MS: int = 250
const KEEP_BREADCRUMBS: int = 12

var stall_ms: int = DEFAULT_STALL_MS
var playtest_log: PlaytestLog

var _mutex: Mutex = Mutex.new()
var _thread: Thread
var _running: bool = false
var _beat_msec: int = 0
var _breadcrumbs: Array[String] = []
var _frozen_since_msec: int = -1


## Starts watching. `log_file` is where freezes get written.
func start(log_file: PlaytestLog, stall_limit_ms: int = DEFAULT_STALL_MS) -> void:
	playtest_log = log_file
	stall_ms = stall_limit_ms
	process_mode = Node.PROCESS_MODE_ALWAYS
	_beat_msec = Time.get_ticks_msec()
	_running = true
	_thread = Thread.new()
	_thread.start(_watch)


## Leave a note about what the game is about to do (cheap; call it often).
func mark(step: String) -> void:
	_mutex.lock()
	_breadcrumbs.append("%.1f %s" % [Time.get_ticks_msec() / 1000.0, step])
	if _breadcrumbs.size() > KEEP_BREADCRUMBS:
		_breadcrumbs.pop_front()
	_mutex.unlock()


func breadcrumbs() -> Array[String]:
	_mutex.lock()
	var copy: Array[String] = _breadcrumbs.duplicate()
	_mutex.unlock()
	return copy


func stop() -> void:
	if not _running:
		return
	_running = false
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()


func _process(_delta: float) -> void:
	var recovered_after: int = -1
	_mutex.lock()
	_beat_msec = Time.get_ticks_msec()
	if _frozen_since_msec >= 0:
		recovered_after = _beat_msec - _frozen_since_msec
		_frozen_since_msec = -1
	_mutex.unlock()
	if recovered_after >= 0 and playtest_log != null:
		playtest_log.write("recovered", {"stuck_ms": recovered_after})


func _exit_tree() -> void:
	stop()


## Runs on the background thread.
func _watch() -> void:
	while _running:
		OS.delay_msec(CHECK_EVERY_MS)
		_mutex.lock()
		var now: int = Time.get_ticks_msec()
		var stalled: int = now - _beat_msec
		var report: bool = stalled >= stall_ms and _frozen_since_msec < 0
		if report:
			_frozen_since_msec = _beat_msec
		var trail: Array[String] = _breadcrumbs.duplicate()
		_mutex.unlock()
		if report and playtest_log != null:
			playtest_log.write("freeze", {"stuck_ms": stalled, "last_steps": trail})
