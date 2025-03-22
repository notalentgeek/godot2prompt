@tool
extends RefCounted
class_name OptionsTabModel

"""
OptionsTabModel represents the data model for the options tab.
It manages the collection of option models and their states.
"""

# Signals
signal options_changed()

# Constants - Option Models Paths
const OPTIONS_MODELS = {
	"errors": "res://addons/godot2prompt/ui/models/options/errors_option_model.gd",
	"project_settings": "res://addons/godot2prompt/ui/models/options/project_settings_option_model.gd",
	"properties": "res://addons/godot2prompt/ui/models/options/properties_option_model.gd",
	"screenshot": "res://addons/godot2prompt/ui/models/options/screenshot_option_model.gd",
	"scripts": "res://addons/godot2prompt/ui/models/options/scripts_option_model.gd",
	"signals": "res://addons/godot2prompt/ui/models/options/signals_option_model.gd"
}

# Option model instances
var _option_models = {}

func _init():
	"""
	Initialize the options tab model by creating all option models.
	"""
	_initialize_option_models()

func _initialize_option_models() -> void:
	"""
	Initialize all option model instances.
	"""
	for option_key in OPTIONS_MODELS.keys():
		var option_model_script = load(OPTIONS_MODELS[option_key])
		if option_model_script:
			var model = option_model_script.new()
			_option_models[option_key] = model

			# Connect to state changes to propagate them up
			model.state_changed.connect(_on_option_state_changed)

func get_option_model(key: String):
	"""
	Get a specific option model by key.

	Args:
		key: The option key (e.g., "scripts", "properties")

	Returns:
		The option model instance, or null if not found
	"""
	return _option_models.get(key)

func get_all_option_models() -> Dictionary:
	"""
	Get all option models.

	Returns:
		Dictionary of all option models with their keys
	"""
	return _option_models.duplicate()

func get_export_options() -> Dictionary:
	"""
	Get a dictionary of export options states.

	Returns:
		Dictionary with option states (e.g., {"include_scripts": true})
	"""
	var export_options = {}

	for option_key in _option_models.keys():
		export_options["include_" + option_key] = _option_models[option_key].is_enabled()

	return export_options

func get_enabled_setting_categories() -> Array:
	"""
	Get enabled project setting categories if project settings option is enabled.

	Returns:
		Array of enabled category names, or empty array if not available
	"""
	if not "project_settings" in _option_models:
		return []

	var project_settings_model = _option_models["project_settings"]
	if not project_settings_model.is_enabled():
		return []

	return project_settings_model.get_enabled_categories()

func _on_option_state_changed(_is_enabled: bool) -> void:
	"""
	Propagate option state changes up to listeners.

	Args:
		_is_enabled: The new state (not used here, just relaying the signal)
	"""
	emit_signal("options_changed")
