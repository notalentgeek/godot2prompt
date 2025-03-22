@tool
extends RefCounted
class_name BaseOptionView

"""
BaseOptionView handles the UI representation of an option.
This is the view component in the MVC pattern, responsible for
creating and managing the visual checkbox control.
"""

# The actual checkbox control
var checkbox: CheckBox = null

# The model this view represents
var model: BaseOptionModel = null

func _init(option_model: BaseOptionModel):
	"""
	Initialize the view with its associated model.

	Args:
		option_model: The data model for this option
	"""
	model = option_model

func create_control() -> Control:
	"""
	Create and configure the checkbox control for this option.

	Returns:
		The configured checkbox control
	"""
	checkbox = CheckBox.new()
	checkbox.text = model.get_text()
	checkbox.tooltip_text = model.get_tooltip()
	checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checkbox.set_pressed(model.is_enabled())

	# Connect the checkbox to update the model
	checkbox.toggled.connect(_on_checkbox_toggled)

	# Connect the model to update the checkbox
	model.state_changed.connect(_on_model_state_changed)

	# Allow subclasses to customize the checkbox
	_setup_control()

	return checkbox

func _setup_control() -> void:
	"""
	Virtual method for subclasses to override for custom setup.
	"""
	pass

func _on_checkbox_toggled(pressed: bool) -> void:
	"""
	Update the model when the checkbox is toggled.

	Args:
		pressed: The new state of the checkbox
	"""
	model.set_enabled(pressed)

func _on_model_state_changed(is_enabled: bool) -> void:
	"""
	Update the checkbox when the model state changes.

	Args:
		is_enabled: The new state from the model
	"""
	if checkbox and checkbox.is_pressed() != is_enabled:
		checkbox.set_pressed(is_enabled)
