@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Project Configuration Exporter - adds project settings information
# Useful for providing context about the project's configuration

# Format the project configuration content
func format_node_content(node_data) -> String:
	var output = ""

	# We only add project settings at the root node level
	if node_data.depth == 0 and "project_settings" in node_data:
		var project_settings = node_data.project_settings
		var enabled_categories = node_data.enabled_setting_categories if "enabled_setting_categories" in node_data else []

		if project_settings and not project_settings.is_empty() and not enabled_categories.is_empty():
			output += "\n\n# Project Settings\n"

			# Group settings by category
			for category in enabled_categories:
				var category_settings = []

				# Gather settings for this category
				for setting in project_settings:
					if setting.name.begins_with(category + "/"):
						category_settings.append(setting)

				# Only show category if it has settings
				if category_settings.size() > 0:
					output += "\n## " + category.capitalize() + "\n"

					# Sort settings by name for consistency
					category_settings.sort_custom(Callable(self, "_sort_settings_by_name"))

					# Output each setting
					for setting in category_settings:
						output += "- " + setting.name + ": " + str(setting.value) + "\n"

	return output

# Helper method to sort settings by name
func _sort_settings_by_name(a, b):
	return a.name < b.name

# Get all available setting categories
static func get_setting_categories() -> Array:
	var categories = {}
	var all_settings = ProjectSettings.get_property_list()

	for setting in all_settings:
		if setting.name.begins_with("_") or setting.name.begins_with("gdscript") or setting.name.begins_with("editor"):
			continue

		var parts = setting.name.split("/")
		if parts.size() > 1:
			categories[parts[0]] = true

	var result = []
	for category in categories.keys():
		result.append(category)

	# Sort alphabetically
	result.sort()

	return result
