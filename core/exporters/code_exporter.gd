@tool
extends BaseExporter
class_name CodeExporter

# Constants
const CODE_BLOCK_END: String = "```"
const CODE_BLOCK_START: String = "```gdscript"
const CONTENT_INDENT: String = "  "
const NEWLINE: String = "\n"

"""
CodeExporter handles the formatting of script code attached to nodes.
It specializes in properly formatting GDScript with appropriate markdown code blocks.
"""

func format_node_content(node_data: NodeData) -> String:
	"""
	Formats the script code for a node with proper indentation and markdown code blocks.

	Args:
		node_data: The NodeData object containing script code to format

	Returns:
		A formatted string containing the node's script code in a markdown code block,
		or an empty string if the node has no script code
	"""
	# Return early if no script code is available
	if not node_data.script_code or node_data.script_code.is_empty():
		return ""

	var base_indent = get_indent(node_data.depth)
	var content_indent = base_indent + CONTENT_INDENT

	# Format the script code as a markdown code block
	var formatted_code = _format_script_as_code_block(node_data.script_code, content_indent)

	return formatted_code + NEWLINE

func _format_script_as_code_block(script_code: String, indent: String) -> String:
	"""
	Wraps script code in markdown code block syntax and applies indentation.

	Args:
		script_code: The raw script code to format
		indent: The indentation string to apply to each line

	Returns:
		Script code formatted as an indented markdown code block
	"""
	# Create the code block wrapper
	var code_block = CODE_BLOCK_START + NEWLINE
	code_block += script_code + NEWLINE
	code_block += CODE_BLOCK_END

	# Apply indentation to each line
	return indent + code_block.replace(NEWLINE, NEWLINE + indent)
