@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Properties exporter - adds node property information
# This adds relevant properties for different node types

# Format just the properties content for a node
func format_node_content(node_data) -> String:
	var output = ""
	var indent = get_indent(node_data.depth)
	
	# Add properties if available
	if node_data.properties and node_data.properties.size() > 0:
		for prop_name in node_data.properties:
			var prop_value = node_data.properties[prop_name]
			output += indent + "    • " + prop_name + ": " + str(prop_value) + "\n"
	
	return output
