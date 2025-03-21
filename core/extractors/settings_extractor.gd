@tool
extends RefCounted
class_name SettingsExtractor

"""
SettingsExtractor extracts project settings from the Godot project.
It filters out internal properties and provides the settings in a structured format.
"""

# Constants - Excluded Prefixes
const EXCLUDED_PREFIXES: Array = ["_", "gdscript", "editor"]

func extract_project_settings() -> Array:
	"""
	Extracts all relevant project settings.

	Returns:
		Array of dictionaries containing setting name-value pairs
	"""
	var settings = []
	var all_settings = ProjectSettings.get_property_list()

	for setting in all_settings:
		if _should_exclude_setting(setting.name):
			continue

		if ProjectSettings.has_setting(setting.name):
			settings.append(_create_setting_entry(setting.name))

	return settings

func _should_exclude_setting(setting_name: String) -> bool:
	"""
	Determines if a setting should be excluded based on its prefix.

	Args:
		setting_name: The name of the setting to check

	Returns:
		True if the setting should be excluded, false otherwise
	"""
	for prefix in EXCLUDED_PREFIXES:
		if setting_name.begins_with(prefix):
			return true

	return false

func _create_setting_entry(setting_name: String) -> Dictionary:
	"""
	Creates a dictionary entry for a setting with its name and value.

	Args:
		setting_name: The name of the setting

	Returns:
		Dictionary containing the setting name and value
	"""
	return {
		"name": setting_name,
		"value": ProjectSettings.get_setting(setting_name)
	}
