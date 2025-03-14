@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Error Context Exporter - adds recent error messages to the output
# This helps LLMs understand issues the developer is facing

# Format the error context for the output
func format_node_content(node_data) -> String:
	var output = ""

	# We only add error context at the root node level
	if node_data.depth == 0 and "error_log" in node_data:
		var error_log = node_data.error_log

		if error_log and error_log.size() > 0:
			output += "\n\nRecent Errors:\n"
			for error in error_log:
				output += "- " + error + "\n"

	return output
