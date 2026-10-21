class_name PlaytestLog
extends RefCounted
## Writes what happens during a playtest to a local file, one JSON object per line,
## so we can tune difficulty afterward. Nothing leaves the computer.
## On Windows the files land in %APPDATA%\Godot\app_userdata\Catch That Critter\playtest\.

const DIR: String = "user://playtest"

var path: String = ""
var _file: FileAccess
var _start_msec: int = 0
## The freeze watchdog writes from its own thread, so writes take turns.
var _mutex: Mutex = Mutex.new()


## Opens a new log file named after the current date and time. Returns false if it can't.
func open(directory: String = DIR) -> bool:
	DirAccess.make_dir_recursive_absolute(directory)
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	path = directory.path_join("playtest_%s.jsonl" % stamp)
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		push_error("PlaytestLog: could not open %s" % path)
		return false
	_start_msec = Time.get_ticks_msec()
	return true


func is_open() -> bool:
	return _file != null


## One event: {"t": seconds since start, "event": type, ...data}. Flushed right away so a crash loses nothing.
func write(event: String, data: Dictionary = {}) -> void:
	_mutex.lock()
	if _file != null:
		var entry: Dictionary = {"t": snappedf((Time.get_ticks_msec() - _start_msec) / 1000.0, 0.1), "event": event}
		entry.merge(data)
		_file.store_line(JSON.stringify(entry))
		_file.flush()
	_mutex.unlock()


func close() -> void:
	_mutex.lock()
	if _file != null:
		_file.close()
		_file = null
	_mutex.unlock()


## Absolute path on this computer (for telling Chris where the file is).
func global_path() -> String:
	return ProjectSettings.globalize_path(path)
