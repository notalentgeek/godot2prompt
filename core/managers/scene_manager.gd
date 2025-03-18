@tool
extends RefCounted

# Node data class reference
var NodeData = load("res://addons/godot2prompt/core/data/node_data.gd")

# Components
var properties_extractor = load("res://addons/godot2prompt/core/managers/scene/properties_extractor.gd").new()
var signals_extractor = load("res://addons/godot2prompt/core/managers/scene/signals_extractor.gd").new()
var settings_extractor = load("res://addons/godot2prompt/core/managers/scene/settings_extractor.gd").new()

# Process the scene and gather data
func process_scene(root: Node, include_properties: bool = false,
				  include_signals: bool = false, error_log: Array = [],
				  include_project_settings: bool = false,
				  enabled_setting_categories: Array = [],
				  screenshot_path: String = ""):
	var project_settings = []

	# If project settings are requested, collect them
	if include_project_settings:
		project_settings = settings_extractor.extract_project_settings()

	return _process_node(root, 0, include_properties, include_signals, error_log,
						 project_settings, enabled_setting_categories, screenshot_path)

# Recursively process each node
func _process_node(node: Node, depth: int, include_properties: bool,
				  include_signals: bool, error_log: Array = [],
				  project_settings: Array = [],
				  enabled_setting_categories: Array = [],
				  screenshot_path: String = ""):
	var script_code = ""
	var properties = {}
	var signals_data = []

	# Get script source code if available
	if node.get_script():
		script_code = node.get_script().get_source_code()

	# Extract properties if requested
	if include_properties:
		properties = properties_extractor.extract_node_properties(node)

	# Extract signals if requested
	if include_signals:
		signals_data = signals_extractor.extract_node_signals(node)

	# Create data for this node - only include error_log and project_settings at the root level
	var node_data
	if depth == 0:
		node_data = NodeData.new(node.name, node.get_class(), depth, script_code,
								 properties, signals_data, error_log, project_settings,
								 enabled_setting_categories, screenshot_path)
	else:
		node_data = NodeData.new(node.name, node.get_class(), depth, script_code,
								 properties, signals_data, [], [],
								 [], "")

	# Process all children
	for child in node.get_children():
		var child_data = _process_node(child, depth + 1, include_properties, include_signals)
		node_data.children.append(child_data)

	return node_data
