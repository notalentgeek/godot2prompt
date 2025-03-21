@tool
extends RefCounted
class_name SceneManager

"""
SceneManager processes scene hierarchies to create a structured representation.
It traverses the scene tree, extracting node data that can be formatted by exporters.
"""

# Constants - Paths
const NODE_DATA_PATH: String = "res://addons/godot2prompt/core/data/node_data.gd"
const PROPERTIES_EXTRACTOR_PATH: String = "res://addons/godot2prompt/core/managers/scene/properties_extractor.gd"
const SETTINGS_EXTRACTOR_PATH: String = "res://addons/godot2prompt/core/managers/scene/settings_extractor.gd"
const SIGNALS_EXTRACTOR_PATH: String = "res://addons/godot2prompt/core/managers/scene/signals_extractor.gd"

# Components
var _node_data_class
var _properties_extractor
var _settings_extractor
var _signals_extractor

func _init() -> void:
	"""
	Initializes the SceneManager and loads required components.
	"""
	_node_data_class = load(NODE_DATA_PATH)
	_properties_extractor = load(PROPERTIES_EXTRACTOR_PATH).new()
	_signals_extractor = load(SIGNALS_EXTRACTOR_PATH).new()
	_settings_extractor = load(SETTINGS_EXTRACTOR_PATH).new()

func process_scene(
	root: Node,
	include_properties: bool = false,
	include_signals: bool = false,
	error_log: Array = [],
	include_project_settings: bool = false,
	enabled_setting_categories: Array = [],
	screenshot_path: String = ""
) -> Object:
	"""
	Processes a scene starting from the root node, collecting node data.

	Args:
		root: The root node of the scene or subtree to process
		include_properties: Whether to include node properties
		include_signals: Whether to include node signals
		error_log: Array of error messages to include with the root node
		include_project_settings: Whether to include project settings
		enabled_setting_categories: Categories of project settings to include
		screenshot_path: Path to a screenshot image, if any

	Returns:
		A NodeData object representing the scene hierarchy
	"""
	var project_settings = []

	# If project settings are requested, collect them
	if include_project_settings:
		project_settings = _settings_extractor.extract_project_settings()

	return _process_node(
		root,
		0,
		include_properties,
		include_signals,
		error_log,
		project_settings,
		enabled_setting_categories,
		screenshot_path
	)

func _process_node(
	node: Node,
	depth: int,
	include_properties: bool,
	include_signals: bool,
	error_log: Array = [],
	project_settings: Array = [],
	enabled_setting_categories: Array = [],
	screenshot_path: String = ""
) -> Object:
	"""
	Recursively processes a node and its children.

	Args:
		node: The node to process
		depth: The depth level in the hierarchy
		include_properties: Whether to include node properties
		include_signals: Whether to include node signals
		error_log: Array of error messages (only included at root level)
		project_settings: Array of project settings (only included at root level)
		enabled_setting_categories: Categories of project settings to include
		screenshot_path: Path to a screenshot image, if any

	Returns:
		A NodeData object representing the node and its children
	"""
	# Extract node data based on requested options
	var node_info = _extract_node_info(node, include_properties, include_signals)

	# Create the appropriate NodeData object based on depth
	var node_data = _create_node_data(
		node,
		depth,
		node_info.script_code,
		node_info.properties,
		node_info.signals_data,
		error_log if depth == 0 else [],
		project_settings if depth == 0 else [],
		enabled_setting_categories if depth == 0 else [],
		screenshot_path if depth == 0 else ""
	)

	# Process all children recursively
	for child in node.get_children():
		var child_data = _process_node(child, depth + 1, include_properties, include_signals)
		node_data.children.append(child_data)

	return node_data

func _extract_node_info(node: Node, include_properties: bool, include_signals: bool) -> Dictionary:
	"""
	Extracts information from a node.

	Args:
		node: The node to extract information from
		include_properties: Whether to extract properties
		include_signals: Whether to extract signals

	Returns:
		Dictionary containing script_code, properties, and signals_data
	"""
	var info = {
		"script_code": "",
		"properties": {},
		"signals_data": []
	}

	# Get script source code if available
	if node.get_script():
		info.script_code = node.get_script().get_source_code()

	# Extract properties if requested
	if include_properties:
		info.properties = _properties_extractor.extract_node_properties(node)

	# Extract signals if requested
	if include_signals:
		info.signals_data = _signals_extractor.extract_node_signals(node)

	return info

func _create_node_data(
	node: Node,
	depth: int,
	script_code: String,
	properties: Dictionary,
	signals_data: Array,
	error_log: Array,
	project_settings: Array,
	enabled_setting_categories: Array,
	screenshot_path: String
) -> Object:
	"""
	Creates a NodeData object with the given parameters.

	Args:
		node: The node to create data for
		depth: The depth level in the hierarchy
		script_code: The node's script source code
		properties: Dictionary of node properties
		signals_data: Array of signal connections
		error_log: Array of error messages
		project_settings: Array of project settings
		enabled_setting_categories: Categories of project settings
		screenshot_path: Path to a screenshot image

	Returns:
		A new NodeData object
	"""
	return _node_data_class.new(
		node.name,
		node.get_class(),
		depth,
		script_code,
		properties,
		signals_data,
		error_log,
		project_settings,
		enabled_setting_categories,
		screenshot_path
	)
