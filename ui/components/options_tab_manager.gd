@tool
extends RefCounted

# UI components
var options_tab: VBoxContainer = null
var options_grid: GridContainer = null

# Option managers - using a more standardized approach
var option_classes = {
	"scripts": "res://addons/godot2prompt/ui/components/options/scripts_option.gd",
	"properties": "res://addons/godot2prompt/ui/components/options/properties_option.gd",
	"signals": "res://addons/godot2prompt/ui/components/options/signals_option.gd",
	"errors": "res://addons/godot2prompt/ui/components/options/errors_option.gd",
	"project_settings": "res://addons/godot2prompt/ui/components/options/project_settings_option.gd",
	"screenshot": "res://addons/godot2prompt/ui/components/options/screenshot_option.gd"
}

# Option instances
var options = {}

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

	# Initialize option instances
	_initialize_options()

	# Add project settings category section if needed
	if "project_settings" in options:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		options_tab.add_child(spacer)

		# Add container for settings categories
		options_tab.add_child(options.project_settings.get_categories_container())

	return options_tab

# Initialize all option instances
func _initialize_options() -> void:
	for option_key in option_classes.keys():
		var option_script = load(option_classes[option_key])
		if option_script:
			options[option_key] = option_script.new()
			options_grid.add_child(options[option_key].create_option())

# Get export options from all option components
func get_export_options() -> Dictionary:
	var export_options = {}

	for option_key in options.keys():
		export_options["include_" + option_key] = options[option_key].is_enabled()

	return export_options

# Populate project settings categories if they exist
func populate_settings_categories() -> void:
	if "project_settings" in options:
		options.project_settings.populate_categories()

# Get enabled setting categories
func get_enabled_setting_categories() -> Array:
	if "project_settings" in options:
		return options.project_settings.get_enabled_categories()
	return []
