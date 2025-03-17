@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Screenshot Exporter - adds screenshot information and path
# Helps provide visual context alongside the scene hierarchy

func format_node_content(node_data) -> String:
	var output = ""

	# We only add screenshot info at the root node level
	if node_data.depth == 0 and "screenshot_path" in node_data and node_data.screenshot_path != "":
		output += "\n\n# Screenshot\n"
		output += "A screenshot of the current scene has been saved at: `" + node_data.screenshot_path + "`\n"

		# Add advice about the screenshot's purpose
		output += "\nThis screenshot provides visual context for the scene structure and layout. "
		output += "It can be helpful for understanding the spatial relationships between nodes and the overall appearance of the scene.\n"

	return output
