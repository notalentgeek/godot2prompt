@tool
extends RefCounted

# UI components
var options_tab: VBoxContainer = null
var options_grid: GridContainer = null

# Option managers
var scripts_option = null
var properties_option = null
var signals_option = null
var errors_option = null
var project_settings_option = null
var screenshot_option = null

# Cached options for reuse
var export_options = {
	"include_scripts": false,
	"include_properties": false,
	"include_signals": false,
	"include_errors": false,
	"include_project_settings": false,
	"include_screenshot": true
}

func create_options_tab() -> Control:
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

	# Initialize option managers
	scripts_option = load("res://addons/godot2prompt/ui/components/options/scripts_option.gd").new()
	properties_option = load("res://addons/godot2prompt/ui/components/options/properties_option.gd").new()
	signals_option = load("res://addons/godot2prompt/ui/components/options/signals_option.gd").new()
	errors_option = load("res://addons/godot2prompt/ui/components/options/errors_option.gd").new()
	project_settings_option = load("res://addons/godot2prompt/ui/components/options/project_settings_option.gd").new()
	screenshot_option = load("res://addons/godot2prompt/ui/components/options/screenshot_option.gd").new()

	# Add options to grid
	options_grid.add_child(scripts_option.create_option())
	options_grid.add_child(properties_option.create_option())
	options_grid.add_child(signals_option.create_option())
	options_grid.add_child(errors_option.create_option())
	options_grid.add_child(project_settings_option.create_option())
	options_grid.add_child(screenshot_option.create_option())

	# Add project settings category section
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	options_tab.add_child(spacer)

	# Add container for settings categories
	options_tab.add_child(project_settings_option.get_categories_container())

	return options_tab

# Get export options from all option components
func get_export_options() -> Dictionary:
	export_options.include_scripts = scripts_option.is_enabled()
	export_options.include_properties = properties_option.is_enabled()
	export_options.include_signals = signals_option.is_enabled()
	export_options.include_errors = errors_option.is_enabled()
	export_options.include_project_settings = project_settings_option.is_enabled()
	export_options.include_screenshot = screenshot_option.is_enabled()

	return export_options

# Populate project settings categories
func populate_settings_categories() -> void:
	project_settings_option.populate_categories()

# Get enabled setting categories
func get_enabled_setting_categories() -> Array:
	return project_settings_option.get_enabled_categories()
