@tool
extends RefCounted

# Maximum number of log files to check
const MAX_LOG_FILES = 3

# Timer for periodically checking the log file
var log_check_timer: Timer = null

# Previous log file positions
var log_positions = {}

# Path to Godot's log directory
var log_dir_path = ""

# Regular expression for parsing errors
var error_regex = RegEx.new()

# Reference to error manager
var error_manager = null

# Initialize the log monitor
func _init():
	# Find the Godot log directory
	_determine_log_dir_path()

	# Compile regex for error detection
	error_regex.compile("(ERROR|SCRIPT ERROR|SCRIPT ERROR:).*")

	# Set up error capturing
	_setup_error_capture()

# Determine the path to Godot's log directory
func _determine_log_dir_path() -> void:
	var user_dir = OS.get_user_data_dir().replace("\\", "/")

	# In Godot 4, the logs are stored in the project directory
	log_dir_path = user_dir + "/logs/"

	print("Godot2Prompt: Monitoring log directory at " + log_dir_path)

# Set up error capturing
func _setup_error_capture() -> void:
	# Create timer for checking log files
	log_check_timer = Timer.new()
	log_check_timer.wait_time = 2.0 # Check every 2 seconds
	log_check_timer.one_shot = false
	log_check_timer.timeout.connect(self._on_log_check_timer_timeout)

	# Get initial log file positions
	_initialize_log_positions()

# Initialize positions for all log files
func _initialize_log_positions() -> void:
	var dir = DirAccess.open(log_dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var log_files_found = 0

		while file_name != "" and log_files_found < MAX_LOG_FILES:
			# Only process log files
			if file_name.ends_with(".log"):
				var full_path = log_dir_path + file_name
				var file = FileAccess.open(full_path, FileAccess.READ)
				if file:
					log_positions[full_path] = file.get_length()
					file.close()
					log_files_found += 1
					print("Godot2Prompt: Monitoring log file: " + file_name)
			file_name = dir.get_next()
	else:
		print("Godot2Prompt: Could not access log directory at " + log_dir_path)

# Start monitoring for errors
func start_monitoring(manager) -> void:
	error_manager = manager
	if log_check_timer and not log_check_timer.is_inside_tree():
		# This needs to be added to the scene tree by the plugin
		pass

# Stop monitoring for errors
func stop_monitoring() -> void:
	if log_check_timer and log_check_timer.is_inside_tree():
		log_check_timer.stop()
		if log_check_timer.get_parent():
			log_check_timer.get_parent().remove_child(log_check_timer)
		print("Godot2Prompt: Error monitoring stopped")

# Timer callback to check the log files
func _on_log_check_timer_timeout() -> void:
	_check_log_files_for_errors()

# Check all log files for new errors
func _check_log_files_for_errors() -> void:
	# First, check if any new log files have appeared
	_check_for_new_log_files()

	# Then check all known log files
	for file_path in log_positions.keys():
		_check_single_log_file(file_path)

# Check for new log files that may have been created
func _check_for_new_log_files() -> void:
	var dir = DirAccess.open(log_dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".log"):
			var full_path = log_dir_path + file_name
			if not log_positions.has(full_path):
				# New log file found, initialize its position
				var file = FileAccess.open(full_path, FileAccess.READ)
				if file:
					# For new files, start from the beginning
					log_positions[full_path] = 0
					file.close()
					print("Godot2Prompt: New log file found: " + file_name)
		file_name = dir.get_next()

# Check a single log file for new errors
func _check_single_log_file(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return

	# Go to the position where we last read
	file.seek(log_positions[file_path])

	# Read new content
	var new_content = file.get_as_text()

	# Update position for next read
	log_positions[file_path] = file.get_length()
	file.close()

	# Process new content for errors
	if new_content.length() > 0:
		_process_log_content(new_content)

# Process log content to extract errors
func _process_log_content(content: String) -> void:
	var lines = content.split("\n")

	for line in lines:
		if line.strip_edges().is_empty():
			continue

		# Check if line contains an error
		var result = error_regex.search(line)
		if result:
			var error_line = line.strip_edges()
			if error_manager:
				error_manager.add_error(error_line)

# Clean up when being destroyed
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if log_check_timer and is_instance_valid(log_check_timer):
			log_check_timer.queue_free()
