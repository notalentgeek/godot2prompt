@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Properties exporter - enhances the tree structure with node properties
# This builds upon the basic tree visualization by adding relevant properties for each node type

func generate_output(node_data) -> String:
	return _format_node_with_properties(node_data)

# Format a single node with properties and its children
func _format_node_with_properties(node_data) -> String:
	var indent = get_indent(node_data.depth)
	var output = indent + "- " + node_data.name + " (" + node_data.type + ")\n"

	# Add properties if available
	if node_data.properties and node_data.properties.size() > 0:
		for prop_name in node_data.properties:
			var prop_value = node_data.properties[prop_name]
			output += indent + "    • " + prop_name + ": " + str(prop_value) + "\n"

	# Process children
	for child in node_data.children:
		output += _format_node_with_properties(child)

	return output
