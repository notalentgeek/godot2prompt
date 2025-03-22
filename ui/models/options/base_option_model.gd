@tool
extends BaseModel
class_name BaseOptionModel

"""
BaseOptionModel represents the data and state for an export option.
This is the model component in the MVC pattern for options, containing
the option's configuration and state.
"""

# Option configuration
var option_text: String = "Option"
var option_tooltip: String = ""
var default_state: bool = false

# Current state
var _is_enabled: bool = false

# Option-specific signal
signal state_changed(is_enabled)

func _init(text: String = "", tooltip: String = "", default: bool = false):
	"""
	Initialize the option model with default values.

	Args:
		text: The display text for the option
		tooltip: The tooltip text for the option
		default: The default state of the option
	"""
	super._init()
	option_text = text if text else option_text
	option_tooltip = tooltip if tooltip else option_tooltip
	default_state = default
	_is_enabled = default

func get_text() -> String:
	"""
	Get the option's display text.

	Returns:
		The text that should be displayed for this option
	"""
	return option_text

func get_tooltip() -> String:
	"""
	Get the option's tooltip text.

	Returns:
		The tooltip text for this option
	"""
	return option_tooltip

func is_enabled() -> bool:
	"""
	Get the current enabled state.

	Returns:
		True if the option is enabled, false otherwise
	"""
	return _is_enabled

func set_enabled(enabled: bool) -> void:
	"""
	Set the enabled state and emit a change signal.

	Args:
		enabled: The new state (true for enabled, false for disabled)
	"""
	if _is_enabled != enabled:
		_is_enabled = enabled
		emit_signal("state_changed", _is_enabled)
		notify_changed() # Notify BaseModel observers

func reset_to_default() -> void:
	"""
	Reset the option state to its default value.
	"""
	set_enabled(default_state)
