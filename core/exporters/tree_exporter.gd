@tool
extends RefCounted

# Generate ASCII tree format output without scripts
func generate_output(node_data) -> String:
	return _format_node(node_data)

# Format a single node and its children
func _format_node(node_data) -> String:
	var indent = "  ".repeat(node_data.depth)
	var output = indent + "- " + node_data.name + " (" + node_data.type + ")\n"

	# Process children
	for child in node_data.children:
		output += _format_node(child)

	return output
