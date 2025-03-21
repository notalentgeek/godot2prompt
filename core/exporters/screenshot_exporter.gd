@tool
extends BaseExporter
class_name ScreenshotExporter

"""
ScreenshotExporter adds screenshot information to the output.
It provides visual context for the scene hierarchy to help understand
the spatial relationships and appearance of the scene.
"""

# Constants
const HELP_TEXT: String = "\nThis screenshot provides visual context for the scene structure and layout. " \
                         +"It can be helpful for understanding the spatial relationships between nodes and the overall appearance of the scene.\n"
const PATH_FORMAT: String = "A screenshot of the current scene has been saved at: `%s`\n"
const SCREENSHOT_HEADER: String = "\n\n# Screenshot\n"

func format_node_content(node_data: NodeData) -> String:
	"""
	Formats screenshot information, but only at the root node level.

	Args:
		node_data: The NodeData object to process

	Returns:
		A formatted string containing screenshot information, or an empty string
		if not at root level or if no screenshot was taken
	"""
	# Return early if not at root level
	if node_data.depth != 0:
		return ""

	# Return early if no screenshot path or empty path
	if not "screenshot_path" in node_data or node_data.screenshot_path.is_empty():
		return ""

	return _format_screenshot_info(node_data.screenshot_path)

func _format_screenshot_info(screenshot_path: String) -> String:
	"""
	Formats screenshot information including path and help text.

	Args:
		screenshot_path: Path to the saved screenshot file

	Returns:
		A formatted string with screenshot information
	"""
	var output = SCREENSHOT_HEADER
	output += PATH_FORMAT % screenshot_path
	output += HELP_TEXT

	return output
