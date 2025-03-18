@tool
extends RefCounted

# Method to extract project settings
func extract_project_settings() -> Array:
	var settings = []
	var all_settings = ProjectSettings.get_property_list()

	for setting in all_settings:
		# Skip internal properties
		if setting.name.begins_with("_") or setting.name.begins_with("gdscript") or setting.name.begins_with("editor"):
			continue

		# Get the value of the setting
		if ProjectSettings.has_setting(setting.name):
			var value = ProjectSettings.get_setting(setting.name)

			# Add to our list
			settings.append({
				"name": setting.name,
				"value": value
			})

	return settings
