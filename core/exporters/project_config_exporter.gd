@tool
extends BaseExporter
class_name ProjectConfigExporter

"""
ProjectConfigExporter adds project settings information to the output.
This provides context about the project's configuration which can be
helpful for LLMs to understand the environment.
"""

# Constants
const CATEGORY_HEADER_FORMAT: String = "\n## %s\n"
const EXCLUDED_PREFIXES: Array = ["_", "gdscript", "editor"]
const PROJECT_SETTINGS_HEADER: String = "\n\n# Project Settings\n"
const SETTING_FORMAT: String = "- %s: %s\n"

func format_node_content(node_data: NodeData) -> String:
	"""
	Formats project configuration settings, but only at the root node level.

	Args:
		node_data: The NodeData object to process

	Returns:
		A formatted string containing project settings, or an empty string
		if not at root level or if there are no enabled setting categories
	"""
	# Return early if not at root level or missing required properties
	if node_data.depth != 0 or not "project_settings" in node_data:
		return ""

	var project_settings = node_data.project_settings
	var enabled_categories = node_data.enabled_setting_categories if "enabled_setting_categories" in node_data else []

	# Return early if settings or categories are empty
	if project_settings.is_empty() or enabled_categories.is_empty():
		return ""

	return _format_project_settings(project_settings, enabled_categories)

static func get_setting_categories() -> Array:
	"""
	Retrieves all available setting categories from the project settings.

	Returns:
		An alphabetically sorted array of setting category names
	"""
	var categories = {}
	var all_settings = ProjectSettings.get_property_list()

	for setting in all_settings:
		if _should_exclude_setting(setting.name):
			continue

		var parts = setting.name.split("/")
		if parts.size() > 1:
			categories[parts[0]] = true

	# Convert dictionary keys to array and sort
	var result = categories.keys()
	result.sort()

	return result

# Private Methods

func _format_project_settings(project_settings: Array, enabled_categories: Array) -> String:
	"""
	Formats project settings grouped by category.

	Args:
		project_settings: Array of project setting objects
		enabled_categories: Array of category names to include

	Returns:
		A formatted string with all enabled project settings
	"""
	var output = PROJECT_SETTINGS_HEADER

	# Process each enabled category
	for category in enabled_categories:
		var category_settings = _get_settings_for_category(project_settings, category)

		# Skip empty categories
		if category_settings.is_empty():
			continue

		# Add category header with capitalized name
		output += CATEGORY_HEADER_FORMAT % category.capitalize()

		# Sort settings by name for consistency
		category_settings.sort_custom(Callable(self, "_sort_settings_by_name"))

		# Add each setting in the category
		for setting in category_settings:
			output += SETTING_FORMAT % [setting.name, str(setting.value)]

	return output

func _get_settings_for_category(project_settings: Array, category: String) -> Array:
	"""
	Filters project settings to only include those from a specific category.

	Args:
		project_settings: Array of all project setting objects
		category: The category name to filter by

	Returns:
		Array of setting objects belonging to the specified category
	"""
	var category_settings = []
	var category_prefix = category + "/"

	for setting in project_settings:
		if setting.name.begins_with(category_prefix):
			category_settings.append(setting)

	return category_settings

func _sort_settings_by_name(a, b) -> bool:
	"""
	Comparison function for sorting settings by name.

	Args:
		a: First setting object
		b: Second setting object

	Returns:
		True if a.name should come before b.name
	"""
	return a.name < b.name

static func _should_exclude_setting(setting_name: String) -> bool:
	"""
	Determines if a setting should be excluded based on its prefix.

	Args:
		setting_name: The name of the setting to check

	Returns:
		True if the setting should be excluded
	"""
	for prefix in EXCLUDED_PREFIXES:
		if setting_name.begins_with(prefix):
			return true

	return false
