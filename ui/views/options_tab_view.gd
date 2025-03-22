@tool
extends RefCounted
class_name OptionsTabView

"""
OptionsTabView creates and manages the UI for the options tab.
It handles the visual representation and layout of option controls.
"""

# UI components
var options_grid: GridContainer = null
var options_tab: VBoxContainer = null

# Option view instances
var _option_views = {}

# Controller reference
var _controller = null

func _init(controller):
	"""
	Initialize the options tab view with a reference to its controller.

	Args:
		controller: The OptionsTabController instance
	"""
	_controller = controller

func create_view() -> Control:
	"""
	Create and configure the options tab view UI.

	Returns:
		The root control for the options tab
	"""
	# Create options tab container
	options_tab = VBoxContainer.new()
	options_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Add export options section
	var options_label = Label.new()
	options_label.text = "Export options:"
	options_tab.add_child(options_label)

	# Options grid container (2 columns for better layout)
	options_grid = GridContainer.new()
	options_grid.columns = 2
	options_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_tab.add_child(options_grid)

	# Initialize option views
	_initialize_option_views()

	# Add project settings category section if needed
	if "project_settings" in _option_views:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		options_tab.add_child(spacer)

		# Add container for settings categories
		var project_settings_view = _option_views["project_settings"]
		options_tab.add_child(project_settings_view.get_categories_container())

	return options_tab

func populate_settings_categories() -> void:
	"""
	Populate project settings categories if the option exists.
	"""
	if "project_settings" in _option_views:
		var project_settings_model = _controller.get_option_model("project_settings")
		if project_settings_model:
			project_settings_model.load_categories()

func _initialize_option_views() -> void:
	"""
	Initialize all option view instances and add them to the UI.
	"""
	# Create views for all option models
	_create_option_views()

	# Add all option views to the grid
	for option_key in _option_views:
		var option_view = _option_views[option_key]
		options_grid.add_child(option_view.create_control())

func _create_option_views() -> void:
	"""
	Create view instances for all option models.
	"""
	# Create ErrorsOptionView
	var errors_model = _controller.get_option_model("errors")
	if errors_model:
		_option_views["errors"] = ErrorsOptionView.new()
		_option_views["errors"].model = errors_model

	# Create ProjectSettingsOptionView
	var project_settings_model = _controller.get_option_model("project_settings")
	if project_settings_model:
		_option_views["project_settings"] = ProjectSettingsOptionView.new()
		_option_views["project_settings"].model = project_settings_model

	# Create PropertiesOptionView
	var properties_model = _controller.get_option_model("properties")
	if properties_model:
		_option_views["properties"] = PropertiesOptionView.new()
		_option_views["properties"].model = properties_model

	# Create ScreenshotOptionView
	var screenshot_model = _controller.get_option_model("screenshot")
	if screenshot_model:
		_option_views["screenshot"] = ScreenshotOptionView.new()
		_option_views["screenshot"].model = screenshot_model

	# Create ScriptsOptionView
	var scripts_model = _controller.get_option_model("scripts")
	if scripts_model:
		_option_views["scripts"] = ScriptsOptionView.new()
		_option_views["scripts"].model = scripts_model

	# Create SignalsOptionView
	var signals_model = _controller.get_option_model("signals")
	if signals_model:
		_option_views["signals"] = SignalsOptionView.new()
		_option_views["signals"].model = signals_model
