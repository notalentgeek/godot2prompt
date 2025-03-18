@tool
extends RefCounted
class_name NodeData

# Node identification
var name: String
var type: String
var depth: int

# Node content
var script_code: String
var properties: Dictionary
var signals: Array

# Export context
var error_log: Array
var project_settings: Array
var enabled_setting_categories: Array
var screenshot_path: String

# Hierarchy
var children: Array

func _init(p_name: String, p_class: String, p_depth: int, p_script: String = "",
		   p_properties: Dictionary = {}, p_signals: Array = [],
		   p_error_log: Array = [], p_project_settings: Array = [],
		   p_enabled_setting_categories: Array = [], p_screenshot_path: String = ""):
	name = p_name
	type = p_class
	depth = p_depth
	script_code = p_script
	properties = p_properties
	signals = p_signals
	error_log = p_error_log
	project_settings = p_project_settings
	enabled_setting_categories = p_enabled_setting_categories
	screenshot_path = p_screenshot_path
	children = []
