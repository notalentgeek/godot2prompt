@tool
extends BaseOptionModel
class_name ProjectSettingsOptionModel

"""
ProjectSettingsOptionModel represents the data for the project settings option.
It manages the list of available categories and their enabled states.
"""

# Signal when categories change
signal categories_updated()

# Special category names that should be capitalized differently
const SPECIAL_CAPITALIZATIONS = {
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

# Path to project config exporter
const PROJECT_CONFIG_EXPORTER_PATH = "res://addons/godot2prompt/core/exporters/project_config_exporter.gd"

# Default categories to use if loading fails
const DEFAULT_CATEGORIES = [
	"application", "audio", "display", "editor",
	"input", "network", "physics", "rendering"
]

# Store categories and their enabled states
var _categories: Array = []
var _category_states: Dictionary = {}

func _init():
	"""
	Initialize with specific settings for the project settings option.
	"""
	super._init(
		"Include Project Settings",
		"Include selected project settings in the export",
		false
	)

	# Connect to our own state change to load categories when needed
	state_changed.connect(_on_state_changed)

func format_category_name(category: String) -> String:
	"""
	Format a category name for display, handling special cases.

	Args:
		category: The raw category name

	Returns:
		Properly formatted category name
	"""
	# Check if the category is in our special cases dictionary first
	if category.to_lower() in SPECIAL_CAPITALIZATIONS:
		return SPECIAL_CAPITALIZATIONS[category.to_lower()]

	# Otherwise capitalize the first letter of each word
	var words = category.split("_")
	for i in range(words.size()):
		words[i] = words[i].capitalize()

	return " ".join(words)

func load_categories() -> void:
	"""
	Load available project setting categories.
	"""
	# Clear existing categories
	_categories.clear()
	_category_states.clear()

	# Try to load categories from the project config exporter
	var categories = _get_categories_from_exporter()

	# Store the categories and set default states
	_categories = categories
	for category in _categories:
		_category_states[category] = true # All enabled by default

	# Notify listeners that categories have been updated
	emit_signal("categories_updated")

func get_categories() -> Array:
	"""
	Get the list of available categories.

	Returns:
		Array of category names
	"""
	return _categories.duplicate()

func get_category_state(category: String) -> bool:
	"""
	Get the enabled state for a specific category.

	Args:
		category: The category name

	Returns:
		True if the category is enabled, false otherwise
	"""
	return _category_states.get(category, false)

func set_category_state(category: String, enabled: bool) -> void:
	"""
	Set the enabled state for a specific category.

	Args:
		category: The category name
		enabled: The new state
	"""
	if category in _categories:
		_category_states[category] = enabled

func get_enabled_categories() -> Array:
	"""
	Get a list of all enabled categories.

	Returns:
		Array of enabled category names
	"""
	var enabled_categories = []

	for category in _categories:
		if get_category_state(category):
			enabled_categories.append(category)

	return enabled_categories

func _get_categories_from_exporter() -> Array:
	"""
	Get categories from the project config exporter.

	Returns:
		Array of category names
	"""
	print("Godot2Prompt: Attempting to load project_config_exporter.gd")

	# Try to load the project settings exporter
	var project_config_exporter_script = load(PROJECT_CONFIG_EXPORTER_PATH)
	if project_config_exporter_script:
		# Create an instance of the exporter
		var project_config_exporter = project_config_exporter_script.new()

		# Get available categories using the instance method
		var categories = project_config_exporter.get_setting_categories()
		print("Godot2Prompt: Found project settings categories: ", categories)

		# If categories were found, return them
		if categories.size() > 0:
			return categories
	else:
		print("Godot2Prompt: Failed to load project_config_exporter.gd")

	# If loading failed or no categories were found, return default categories
	print("Godot2Prompt: Using default categories")
	return DEFAULT_CATEGORIES.duplicate()

func _on_state_changed(is_enabled: bool) -> void:
	"""
	When the option is enabled, load categories if they haven't been loaded yet.

	Args:
		is_enabled: The new state of the option
	"""
	if is_enabled and _categories.is_empty():
		load_categories()
