@tool
extends BaseExporter
class_name PropertiesExporter

"""
PropertiesExporter formats node property information for output.
This adds relevant properties for different node types to help
provide context about the node's configuration.
"""

# Constants
const PROPERTY_INDENT: String = "    "
const PROPERTY_PREFIX: String = "• "
const PROPERTY_FORMAT: String = "%s: %s\n"

func format_node_content(node_data: NodeData) -> String:
	"""
	Formats the properties of a node with proper indentation.

	Args:
		node_data: The NodeData object containing properties to format

	Returns:
		A formatted string containing the node's properties,
		or an empty string if the node has no properties
	"""
	# Return early if no properties are available
	if not node_data.properties or node_data.properties.is_empty():
		return ""

	return _format_properties(node_data.properties, node_data.depth)

func _format_properties(properties: Dictionary, depth: int) -> String:
	"""
	Formats a dictionary of properties with proper indentation.

	Args:
		properties: Dictionary of property name-value pairs
		depth: The depth level for proper indentation

	Returns:
		A formatted string with all properties
	"""
	var output = ""
	var base_indent = get_indent(depth)
	var full_indent = base_indent + PROPERTY_INDENT

	# Sort property names alphabetically for consistent output
	var property_names = properties.keys()
	property_names.sort()

	# Format each property with proper indentation
	for prop_name in property_names:
		var prop_value = properties[prop_name]
		output += full_indent + PROPERTY_PREFIX + PROPERTY_FORMAT % [prop_name, str(prop_value)]

	return output
