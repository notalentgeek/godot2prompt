@tool
extends RefCounted
class_name LogMonitor

"""
LogMonitor watches Godot log files and extracts error messages.
It periodically checks log files for new errors and reports them to the error manager.
"""

# Constants
const MAX_LOG_FILES: int = 3
const LOG_CHECK_INTERVAL: float = 2.0

# Constants - Log Messages
const LOG_DIR_MONITORING: String = "Godot2Prompt: Monitoring log directory at %s"
const LOG_DIR_ACCESS_FAILED: String = "Godot2Prompt: Could not access log directory at %s"
const LOG_FILE_MONITORING: String = "Godot2Prompt: Monitoring log file: %s"
const LOG_FILE_NEW: String = "Godot2Prompt: New log file found: %s"
const LOG_MONITORING_STOPPED: String = "Godot2Prompt: Error monitoring stopped"

# Properties - Keep log_check_timer public for backward compatibility
var log_check_timer: Timer = null

# Private Properties
var _error_manager = null
var _log_dir_path: String = ""
var _log_positions: Dictionary = {}
var _error_regex: RegEx = RegEx.new()

func _init() -> void:
	"""
	Initializes the log monitor by setting up the log directory path and error detection.
	"""
	_determine_log_dir_path()
	_compile_error_regex()
	_setup_error_capture()

func start_monitoring(manager) -> void:
	"""
	Starts monitoring log files for errors.

	Args:
		manager: The error manager to report errors to
	"""
	_error_manager = manager
	# Note: Timer must be added to the scene tree by the plugin

func stop_monitoring() -> void:
	"""
	Stops monitoring log files for errors and cleans up resources.
	"""
	if log_check_timer and log_check_timer.is_inside_tree():
		log_check_timer.stop()
		if log_check_timer.get_parent():
			log_check_timer.get_parent().remove_child(log_check_timer)
		print(LOG_MONITORING_STOPPED)

# Private Methods - Setup

func _determine_log_dir_path() -> void:
	"""
	Determines the path to Godot's log directory.
	"""
	var user_dir = OS.get_user_data_dir().replace("\\", "/")
	_log_dir_path = user_dir + "/logs/"
	print(LOG_DIR_MONITORING % _log_dir_path)

func _compile_error_regex() -> void:
	"""
	Compiles the regular expression used to detect errors in log files.
	"""
	_error_regex.compile("(ERROR|SCRIPT ERROR|SCRIPT ERROR:).*")

func _setup_error_capture() -> void:
	"""
	Sets up the timer and initial state for capturing errors from log files.
	"""
	# Create timer for checking log files
	log_check_timer = Timer.new()
	log_check_timer.wait_time = LOG_CHECK_INTERVAL
	log_check_timer.one_shot = false
	log_check_timer.timeout.connect(self._on_log_check_timer_timeout)

	# Get initial log file positions
	_initialize_log_positions()

func _initialize_log_positions() -> void:
	"""
	Initializes the positions for all existing log files.
	"""
	var dir = DirAccess.open(_log_dir_path)
	if not dir:
		print(LOG_DIR_ACCESS_FAILED % _log_dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var log_files_found = 0

	while file_name != "" and log_files_found < MAX_LOG_FILES:
		# Only process log files
		if file_name.ends_with(".log"):
			var full_path = _log_dir_path + file_name
			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				_log_positions[full_path] = file.get_length()
				file.close()
				log_files_found += 1
				print(LOG_FILE_MONITORING % file_name)
		file_name = dir.get_next()

# Private Methods - Log Checking

func _on_log_check_timer_timeout() -> void:
	"""
	Timer callback that triggers checking log files for new errors.
	"""
	_check_log_files_for_errors()

func _check_log_files_for_errors() -> void:
	"""
	Checks all log files for new errors.
	"""
	# First, check if any new log files have appeared
	_check_for_new_log_files()

	# Then check all known log files
	for file_path in _log_positions.keys():
		_check_single_log_file(file_path)

func _check_for_new_log_files() -> void:
	"""
	Checks for new log files that may have been created since last check.
	"""
	var dir = DirAccess.open(_log_dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".log"):
			var full_path = _log_dir_path + file_name
			if not _log_positions.has(full_path):
				# New log file found, initialize its position
				var file = FileAccess.open(full_path, FileAccess.READ)
				if file:
					# For new files, start from the beginning
					_log_positions[full_path] = 0
					file.close()
					print(LOG_FILE_NEW % file_name)
		file_name = dir.get_next()

func _check_single_log_file(file_path: String) -> void:
	"""
	Checks a single log file for new errors.

	Args:
		file_path: Path to the log file to check
	"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return

	# Go to the position where we last read
	file.seek(_log_positions[file_path])

	# Read new content
	var new_content = file.get_as_text()

	# Update position for next read
	_log_positions[file_path] = file.get_length()
	file.close()

	# Process new content for errors
	if not new_content.is_empty():
		_process_log_content(new_content)

func _process_log_content(content: String) -> void:
	"""
	Processes log content to extract errors.

	Args:
		content: The log content to process
	"""
	var lines = content.split("\n")

	for line in lines:
		if line.strip_edges().is_empty():
			continue

		# Check if line contains an error
		var result = _error_regex.search(line)
		if result and _error_manager:
			var error_line = line.strip_edges()
			_error_manager.add_error(error_line)

# Cleanup

func _notification(what: int) -> void:
	"""
	Handles cleanup when the object is being destroyed.

	Args:
		what: The notification type
	"""
	if what == NOTIFICATION_PREDELETE:
		if log_check_timer and is_instance_valid(log_check_timer):
			log_check_timer.queue_free()
