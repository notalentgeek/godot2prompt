@tool
extends BaseExporter
class_name ErrorContextExporter

"""
ErrorContextExporter adds recent error messages to the output.
This helps LLMs understand issues the developer is facing when interpreting
the scene hierarchy.
"""

# Constants
const ERROR_HEADER: String = "\n\nRecent Errors:\n"
const ERROR_PREFIX: String = "- "

func format_node_content(node_data: NodeData) -> String:
	"""
	Formats error log information, but only at the root node level.

	Args:
		node_data: The NodeData object to process

	Returns:
		A formatted string containing error messages, or an empty string
		if there are no errors or if this isn't the root node
	"""
	# Return early if not at root level or if there's no error_log property
	if node_data.depth != 0 or not "error_log" in node_data:
		return ""

	return _format_error_log(node_data.error_log)

func _format_error_log(error_log: Array) -> String:
	"""
	Formats the error log array into a readable list.

	Args:
		error_log: Array of error message strings

	Returns:
		A formatted string with all error messages, or an empty string
		if there are no errors
	"""
	# Return early if there are no errors
	if error_log.is_empty():
		return ""

	var output = ERROR_HEADER

	for error in error_log:
		output += ERROR_PREFIX + error + "\n"

	return output
