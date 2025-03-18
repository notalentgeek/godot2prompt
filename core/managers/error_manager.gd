@tool
extends RefCounted

# Maximum number of errors to store
const MAX_ERRORS = 10

# Error log storage
var error_log = []

# Components
var log_monitor = null

func _init():
	# Initialize the log monitor
	log_monitor = load("res://addons/godot2prompt/core/managers/error/log_monitor.gd").new()

# Start monitoring for errors
func start_monitoring() -> void:
	log_monitor.start_monitoring(self)

# Stop monitoring for errors
func stop_monitoring() -> void:
	log_monitor.stop_monitoring()

# Add an error to the log
func add_error(message: String) -> void:
	# Check if this error is already logged (avoid duplicates)
	if error_log.has(message):
		return

	# Add the error
	error_log.append(message)

	# Keep only the most recent errors
	if error_log.size() > MAX_ERRORS:
		error_log.pop_front()

	print("Godot2Prompt: Captured error: " + message)

# Clear the error log
func clear_errors() -> void:
	error_log.clear()

# Get the current error log
func get_errors() -> Array:
	return error_log.duplicate()

# Clean up
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if log_monitor:
			log_monitor = null
