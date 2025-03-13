@tool
extends "res://addons/godot2prompt/core/exporters/base_exporter.gd"

# Combined exporter - includes both node properties and scripts
# Provides the most comprehensive output for LLM context

func generate_output(node_data) -> String:
	return _format_node_with_properties_and_scripts(node_data)

# Format a node with both properties and script code
func _format_node_with_properties_and_scripts(node_data) -> String:
	var indent = get_indent(node_data.depth)
	var output = indent + "- " + node_data.name + " (" + node_data.type + ")\n"

	# Add properties if available
	if node_data.properties and node_data.properties.size() > 0:
		for prop_name in node_data.properties:
			var prop_value = node_data.properties[prop_name]
			output += indent + "    • " + prop_name + ": " + str(prop_value) + "\n"

	# Add script code if available
	if node_data.script_code and node_data.script_code.length() > 0:
		var script_text = "```gdscript\n" + node_data.script_code + "\n```\n"
		output += indent + "  " + script_text.replace("\n", "\n" + indent + "  ") + "\n"

	# Process children
	for child in node_data.children:
		output += _format_node_with_properties_and_scripts(child)

	return output
