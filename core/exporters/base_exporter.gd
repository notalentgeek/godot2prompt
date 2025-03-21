@tool
extends RefCounted
class_name BaseExporter

# Constants
const INDENT_STRING: String = "  "
const NODE_PREFIX: String = "- "

"""
Base class for all exporters in the Godot2Prompt system.
This establishes the contract (interface) that all exporter implementations must follow.
Each derived exporter is responsible for formatting specific aspects of node data.
"""

# Public Methods

func generate_output(node_data: NodeData) -> String:
	"""
	Recursively formats an entire node hierarchy starting from the provided node.

	Args:
		node_data: The root NodeData object to format

	Returns:
		A formatted string representation of the node and all its descendants
	"""
	var output = format_node_line(node_data)
	output += format_node_content(node_data)

	# Recursively process all children
	for child in node_data.children:
		output += generate_output(child)

	return output

func format_node_line(node_data: NodeData) -> String:
	"""
	Formats the identification line for a node.

	Args:
		node_data: The NodeData object to format

	Returns:
		A string representing the node's name and type with proper indentation
	"""
	var indent = get_indent(node_data.depth)

	return indent + NODE_PREFIX + node_data.name + " (" + node_data.type + ")\n"

func format_node_content(node_data: NodeData) -> String:
	"""
	Formats the content for a node (properties, scripts, etc.).
	This is a virtual method that should be overridden by derived classes.

	Args:
		node_data: The NodeData object whose content should be formatted

	Returns:
		A string containing the formatted node content (empty in base class)
	"""
	return ""

# Utility Methods

func get_indent(depth: int) -> String:
	"""
	Creates an indentation string based on the node's depth.

	Args:
		depth: The depth level of the node in the hierarchy

	Returns:
		A string with the appropriate number of spaces for indentation
	"""
	return INDENT_STRING.repeat(depth)
