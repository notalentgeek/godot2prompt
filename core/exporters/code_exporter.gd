@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Code exporter - adds script code to the output
# This includes the GDScript attached to nodes

# Format just the script content for a node
func format_node_content(node_data) -> String:
	var output = ""
	var indent = get_indent(node_data.depth)
	
	# Add script code if available
	if node_data.script_code and node_data.script_code.length() > 0:
		var script_text = "```gdscript\n" + node_data.script_code + "\n```\n"
		output += indent + "  " + script_text.replace("\n", "\n" + indent + "  ") + "\n"
	
	return output
