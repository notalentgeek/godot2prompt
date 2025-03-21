@tool
extends RefCounted
class_name NodeData

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
