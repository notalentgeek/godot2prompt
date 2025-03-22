@tool
extends BaseModel
class_name ProgressDialogModel

"""
ProgressDialogModel represents the data model for the export progress dialog.
It manages the progress state and messages.
"""

# Specific signals
signal progress_updated(progress, message)

# Constants
const INITIAL_MESSAGE: String = "Initializing export..."

# Properties
var _current_progress: int = 0
var _current_message: String = INITIAL_MESSAGE

func _init():
	"""
	Initialize the progress dialog model with default values.
	"""
	super._init()
	reset()

func reset() -> void:
	"""
	Reset the progress to initial state.
	"""
	_current_progress = 0
	_current_message = INITIAL_MESSAGE
	emit_signal("progress_updated", _current_progress, _current_message)
	notify_changed() # Notify BaseModel observers

func update_progress(progress: int, message: String) -> void:
	"""
	Update the current progress and message.

	Args:
		progress: The new progress value (0-100)
		message: The new status message
	"""
	var should_emit = false

	# Update progress if changed
	if _current_progress != progress:
		_current_progress = progress
		should_emit = true

	# Update message if changed
	if _current_message != message:
		_current_message = message
		should_emit = true

	# Notify listeners of changes
	if should_emit:
		emit_signal("progress_updated", _current_progress, _current_message)
		notify_changed() # Notify BaseModel observers

func get_progress() -> int:
	"""
	Get the current progress value.

	Returns:
		The current progress value (0-100)
	"""
	return _current_progress

func get_message() -> String:
	"""
	Get the current status message.

	Returns:
		The current status message
	"""
	return _current_message
