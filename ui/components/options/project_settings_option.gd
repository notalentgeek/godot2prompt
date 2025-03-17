@tool
extends RefCounted

# UI components
var include_project_settings_checkbox: CheckBox = null
var categories_label: Label = null
var categories_scroll: ScrollContainer = null
var settings_categories_container: VBoxContainer = null
var category_checkboxes = {} # Dictionary of category name to checkbox
var categories_container: VBoxContainer = null

# Special category names that should be capitalized differently
var special_capitalizations = {
	"2d": "2D",
	"3d": "3D",
	"api": "API",
	"ar": "AR",
	"bvh": "BVH",
	"cpu": "CPU",
	"csg": "CSG",
	"fft": "FFT",
	"gdscript": "GDScript",
	"gles2": "GLES2",
	"gles3": "GLES3",
	"gpu": "GPU",
	"gui": "GUI",
	"html5": "HTML5",
	"http": "HTTP",
	"ios": "iOS",
	"macos": "macOS",
	"osx": "OSX",
	"ssl": "SSL",
	"tcp": "TCP",
	"tls": "TLS",
	"udp": "UDP",
	"ui": "UI",
	"url": "URL",
	"vr": "VR",
	"vram": "VRAM",
	"vsync": "VSync",
	"wp8": "WP8",
	"x11": "X11",
	"xr": "XR",
}

func create_option() -> Control:
	include_project_settings_checkbox = CheckBox.new()
	include_project_settings_checkbox.text = "Include Project Settings"
	include_project_settings_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	include_project_settings_checkbox.set_pressed(false)
	include_project_settings_checkbox.tooltip_text = "Include selected project settings in the export"
	include_project_settings_checkbox.connect("toggled", Callable(self, "_on_project_settings_toggled"))

	# Create categories container
	categories_container = VBoxContainer.new()
	categories_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Create categories label (initially hidden)
	categories_label = Label.new()
	categories_label.text = "Project Settings Categories:"
	categories_label.visible = false
	categories_container.add_child(categories_label)

	# Create scrollable container for categories (initially hidden)
	categories_scroll = ScrollContainer.new()
	categories_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	categories_scroll.visible = false
	categories_container.add_child(categories_scroll)

	# Create the container for the checkboxes
	settings_categories_container = VBoxContainer.new()
	settings_categories_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories_scroll.add_child(settings_categories_container)

	return include_project_settings_checkbox

# Get the container for categories to add to the main options tab
func get_categories_container() -> Control:
	return categories_container

func is_enabled() -> bool:
	return include_project_settings_checkbox.is_pressed()

func _on_project_settings_toggled(button_pressed: bool) -> void:
	# Show/hide the categories section based on checkbox state
	categories_label.visible = button_pressed
	categories_scroll.visible = button_pressed

	# If toggling on and no categories populated, populate them now
	if button_pressed and category_checkboxes.size() == 0:
		populate_categories()

# Function to properly format category name
func _format_category_name(category: String) -> String:
	# Check if the category is in our special cases dictionary first
	if category.to_lower() in special_capitalizations:
		return special_capitalizations[category.to_lower()]

	# Otherwise capitalize the first letter of each word
	var words = category.split("_")
	for i in range(words.size()):
		words[i] = words[i].capitalize()

	return " ".join(words)

func populate_categories() -> void:
	# Clear existing categories
	for child in settings_categories_container.get_children():
		child.queue_free()

	category_checkboxes.clear()

	# DEBUG: Print information about loading the exporter
	print("Godot2Prompt: Attempting to load project_config_exporter.gd")

	# Load the project settings exporter
	var project_config_exporter_script = load("res://addons/godot2prompt/core/exporters/project_config_exporter.gd")
	if project_config_exporter_script:
		# Create an instance of the exporter
		var project_config_exporter = project_config_exporter_script.new()

		# Get available categories using the instance method
		var categories = project_config_exporter.get_setting_categories()
		print("Godot2Prompt: Found project settings categories: ", categories)

		# If no categories were found, try to generate some default ones
		if categories.size() == 0:
			print("Godot2Prompt: No categories found, using default categories")
			categories = ["application", "audio", "display", "editor", "input", "network", "physics", "rendering"]

		# Create a checkbox for each category
		for category in categories:
			var checkbox = CheckBox.new()
			checkbox.text = _format_category_name(category)
			checkbox.set_pressed(true) # All categories checked by default
			settings_categories_container.add_child(checkbox)

			# Store reference to checkbox
			category_checkboxes[category] = checkbox
	else:
		print("Godot2Prompt: Failed to load project_config_exporter.gd")

		# Create some default categories as fallback
		var fallback_categories = ["application", "audio", "display", "editor", "input", "network", "physics", "rendering"]
		for category in fallback_categories:
			var checkbox = CheckBox.new()
			checkbox.text = _format_category_name(category)
			checkbox.set_pressed(true)
			settings_categories_container.add_child(checkbox)
			category_checkboxes[category] = checkbox

func get_enabled_categories() -> Array:
	var enabled_categories = []

	for category in category_checkboxes.keys():
		if category_checkboxes[category].is_pressed():
			enabled_categories.append(category)

	return enabled_categories
