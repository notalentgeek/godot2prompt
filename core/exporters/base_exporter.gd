@tool
extends RefCounted

# Base class for all exporters
# This establishes the contract that all exporters must follow

# Format an entire node hierarchy
func generate_output(node_data) -> String:
	var output = format_node_line(node_data)
	output += format_node_content(node_data)
	
	# Process children
	for child in node_data.children:
		output += generate_output(child)
	
	return output

# Format just the node identification line
func format_node_line(node_data) -> String:
	var indent = get_indent(node_data.depth)
	return indent + "- " + node_data.name + " (" + node_data.type + ")\n"

# Format the content for a node (properties, scripts, etc.)
# To be overridden by derived classes
func format_node_content(node_data) -> String:
	return ""

# Common utility methods that all exporters might need
func get_indent(depth: int) -> String:
	return "  ".repeat(depth)
