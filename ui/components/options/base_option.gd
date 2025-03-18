@tool
extends RefCounted
class_name BaseOption

# The actual checkbox control
var checkbox: CheckBox = null

# Default configuration
var option_text: String = "Option"
var option_tooltip: String = ""
var default_state: bool = false

func _init(text: String = "", tooltip: String = "", default: bool = false):
	option_text = text if text else option_text
	option_tooltip = tooltip if tooltip else option_tooltip
	default_state = default

# Create the checkbox option
func create_option() -> Control:
	checkbox = CheckBox.new()
	checkbox.text = option_text
	checkbox.tooltip_text = option_tooltip
	checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checkbox.set_pressed(default_state)

	# Allow subclasses to customize the checkbox
	_setup_option()

	return checkbox

# Virtual method for subclasses to override
func _setup_option() -> void:
	pass

# Get the enabled status
func is_enabled() -> bool:
	return checkbox and checkbox.is_pressed()
