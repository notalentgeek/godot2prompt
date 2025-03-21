@tool
extends RefCounted
class_name ErrorManager

"""
ErrorManager handles error tracking and logging for the Godot2Prompt plugin.
It maintains a limited history of errors and integrates with the log monitoring system.
"""

# Constants
const LOG_MONITOR_PATH: String = "res://addons/godot2prompt/core/managers/error/log_monitor.gd"
const MAX_ERRORS: int = 10
const PREFIX_LOG: String = "Godot2Prompt: Captured error: %s"

# Properties
var _error_log: Array = []
var log_monitor = null

func _init() -> void:
	"""
	Initializes the ErrorManager and creates the log monitor.
	"""
	log_monitor = load(LOG_MONITOR_PATH).new()

# Public Methods

func add_error(message: String) -> void:
	"""
	Adds an error message to the log if it's not already present.

	Args:
		message: The error message to add
	"""
	# Skip duplicate errors
	if _error_log.has(message):
		return

	# Add the error
	_error_log.append(message)

	# Maintain maximum size by removing oldest errors
	if _error_log.size() > MAX_ERRORS:
		_error_log.pop_front()

	print(PREFIX_LOG % message)

func clear_errors() -> void:
	"""
	Removes all errors from the log.
	"""
	_error_log.clear()

func get_errors() -> Array:
	"""
	Returns a copy of the current error log.

	Returns:
		An array of error message strings
	"""
	return _error_log.duplicate()

func start_monitoring() -> void:
	"""
	Begins monitoring for errors using the log monitor.
	"""
	if log_monitor:
		log_monitor.start_monitoring(self)

func stop_monitoring() -> void:
	"""
	Stops monitoring for errors.
	"""
	if log_monitor:
		log_monitor.stop_monitoring()

# Cleanup

func _notification(what: int) -> void:
	"""
	Handles object cleanup when being deleted.

	Args:
		what: The notification type
	"""
	if what == NOTIFICATION_PREDELETE:
		if log_monitor:
			log_monitor = null
