@tool
extends BaseController
class_name OptionsTabController

"""
OptionsTabController coordinates between the options tab model and view.
It handles user interactions and forwards data between the model and view.
"""

func _init():
	"""
	Initialize the controller by creating model and view instances.
	"""
	super._init()
	_model = OptionsTabModel.new()
	_view = OptionsTabView.new(self)

func create_options_tab() -> Control:
	"""
	Create and return the options tab control.

	Returns:
		The root control for the options tab
	"""
	return _view.create_view()

func get_option_model(key: String):
	"""
	Get a specific option model by key.

	Args:
		key: The option key (e.g., "scripts", "properties")

	Returns:
		The option model instance, or null if not found
	"""
	return _model.get_option_model(key)

func get_export_options() -> Dictionary:
	"""
	Get the current export options states.

	Returns:
		Dictionary of option states (e.g., {"include_scripts": true})
	"""
	return _model.get_export_options()

func populate_settings_categories() -> void:
	"""
	Populate project settings categories.
	"""
	_view.populate_settings_categories()

func get_enabled_setting_categories() -> Array:
	"""
	Get the list of enabled project setting categories.

	Returns:
		Array of enabled category names
	"""
	return _model.get_enabled_setting_categories()
