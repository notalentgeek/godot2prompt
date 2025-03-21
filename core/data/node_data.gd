@tool
extends RefCounted
class_name NodeData

"""
NodeData represents a single node in the scene hierarchy with all its properties.
This class stores the complete information about a node that can be exported,
including its identification, content, hierarchy, and export context information.
"""

# Properties - Export Context
var enabled_setting_categories: Array
var error_log: Array
var project_settings: Array
var screenshot_path: String

# Properties - Hierarchy
var children: Array

# Properties - Node Identification
var depth: int
var name: String
var type: String

# Properties - Node Content
var properties: Dictionary
var script_code: String
var signals: Array

# Constructor
func _init(
	p_name: String,
	p_class: String,
	p_depth: int,
	p_script: String = "",
	p_properties: Dictionary = {},
	p_signals: Array = [],
	p_error_log: Array = [],
	p_project_settings: Array = [],
	p_enabled_setting_categories: Array = [],
	p_screenshot_path: String = ""
):
	"""
	Initializes a new NodeData instance with the provided information.

	Args:
		p_name: The name of the node
		p_class: The class/type of the node
		p_depth: The depth level of the node in the hierarchy
		p_script: The associated script code as a string
		p_properties: Dictionary of the node's properties and their values
		p_signals: Array of signal connections associated with the node
		p_error_log: Array of error messages for context
		p_project_settings: Array of project settings for context
		p_enabled_setting_categories: Array of enabled setting categories
		p_screenshot_path: Path to the screenshot image if available
	"""
	# Node Identification
	depth = p_depth
	name = p_name
	type = p_class

	# Node Content
	properties = p_properties
	script_code = p_script
	signals = p_signals

	# Export Context
	enabled_setting_categories = p_enabled_setting_categories
	error_log = p_error_log
	project_settings = p_project_settings
	screenshot_path = p_screenshot_path

	# Initialize empty children array
	children = []
