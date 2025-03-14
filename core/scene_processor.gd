@tool
extends RefCounted

# A class to represent node data
class NodeData:
	var name: String
	var type: String
	var script_code: String
	var properties: Dictionary
	var signals: Array
	var error_log: Array # Added error_log
	var children: Array
	var depth: int

	func _init(p_name: String, p_class: String, p_depth: int, p_script: String = "", p_properties: Dictionary = {}, p_signals: Array = [], p_error_log: Array = []):
		name = p_name
		type = p_class
		depth = p_depth
		script_code = p_script
		properties = p_properties
		signals = p_signals
		error_log = p_error_log
		children = []

# Process the scene and gather data
func process_scene(root: Node, include_properties: bool = false, include_signals: bool = false, error_log: Array = []) -> NodeData:
	return _process_node(root, 0, include_properties, include_signals, error_log)

# Recursively process each node
func _process_node(node: Node, depth: int, include_properties: bool, include_signals: bool, error_log: Array = []) -> NodeData:
	var script_code = ""
	var properties = {}
	var signals_data = []

	# Get script source code if available
	if node.get_script():
		script_code = node.get_script().get_source_code()

	# Extract properties if requested
	if include_properties:
		properties = _extract_node_properties(node)

	# Extract signals if requested
	if include_signals:
		signals_data = _extract_node_signals(node)

	# Create data for this node - only include error_log for the root node
	var node_data
	if depth == 0:
		node_data = NodeData.new(node.name, node.get_class(), depth, script_code, properties, signals_data, error_log)
	else:
		node_data = NodeData.new(node.name, node.get_class(), depth, script_code, properties, signals_data, [])

	# Process all children
	for child in node.get_children():
		var child_data = _process_node(child, depth + 1, include_properties, include_signals)
		node_data.children.append(child_data)

	return node_data

# Extract relevant properties based on node type
func _extract_node_properties(node: Node) -> Dictionary:
	var properties = {}

	# Common Node properties
	properties["Unique Name"] = node.name

	# CanvasItem properties (2D nodes)
	if node is CanvasItem:
		properties["Position"] = node.position
		properties["Scale"] = node.scale
		properties["Rotation"] = node.rotation
		properties["Visible"] = node.visible
		properties["Modulate"] = node.modulate

		# Control-specific properties
		if node is Control:
			properties["Size"] = node.size
			properties["Layout Mode"] = node.size_flags_horizontal
			if "text" in node:
				properties["Text"] = node.text

	# Add more properties here

	return properties

# Extract signal connections from a node
func _extract_node_signals(node: Node) -> Array:
	var signals_data = []

	# First get outgoing connections (signals emitted by this node)
	_get_outgoing_connections(node, signals_data)

	# Then get incoming connections (signals connected to this node's methods)
	_get_incoming_connections(node, signals_data)

	return signals_data

# Get signals that this node emits (outgoing)
func _get_outgoing_connections(node: Node, signals_data: Array) -> void:
	# Get all signals defined by this node
	var signals_list = []

	# Get script signals if available
	if node.get_script():
		signals_list.append_array(node.get_script().get_script_signal_list())

	# Use ClassDB to get all signals for this node type
	var node_type = node.get_class()
	var class_signals = ClassDB.class_get_signal_list(node_type)

	# Add class signals to our list
	for signal_dict in class_signals:
		signals_list.append(signal_dict.name)

	# Check each signal for connections
	for signal_name in signals_list:
		if signal_name is Dictionary and "name" in signal_name:
			signal_name = signal_name.name

		if node.has_signal(signal_name):
			var connections = node.get_signal_connection_list(signal_name)

			# Process each connection
			for connection in connections:
				var target_name = "Unknown"
				var method_name = ""

				if "callable" in connection:
					var callable = connection.callable
					if callable.get_object() and is_instance_valid(callable.get_object()):
						var target_obj = callable.get_object()

						# Different objects have different ways to identify them
						if target_obj is Node:
							target_name = target_obj.name
						elif "name" in target_obj:
							target_name = target_obj.name
						else:
							target_name = target_obj.get_class()

						method_name = callable.get_method()

					signals_data.append({
						"signal_name": signal_name,
						"direction": "outgoing",
						"target": target_name,
						"method": method_name
					})

# Get signals connected to this node's methods (incoming)
func _get_incoming_connections(node: Node, signals_data: Array) -> void:
	# Check all other nodes in the tree
	var root = node.get_tree().get_root() if node.get_tree() else null
	if root:
		_find_signals_targeting_node(root, node, signals_data)

# Recursively search for signals targeting the specified node
func _find_signals_targeting_node(search_node: Node, target_node: Node, signals_data: Array) -> void:
	# Get all signals from this search node
	var signals_list = []

	# Get script signals if available
	if search_node.get_script():
		signals_list.append_array(search_node.get_script().get_script_signal_list())

	# Use ClassDB to get all signals for this node type
	var node_type = search_node.get_class()
	var class_signals = ClassDB.class_get_signal_list(node_type)

	# Add class signals to our list
	for signal_dict in class_signals:
		signals_list.append(signal_dict.name)

	# Check each signal for connections to our target node
	for signal_name in signals_list:
		if signal_name is Dictionary and "name" in signal_name:
			signal_name = signal_name.name

		if search_node.has_signal(signal_name):
			var connections = search_node.get_signal_connection_list(signal_name)

			# See if any connection points to our target node
			for connection in connections:
				if "callable" in connection:
					var callable = connection.callable
					if callable.get_object() == target_node:
						signals_data.append({
							"signal_name": signal_name,
							"direction": "incoming",
							"source": search_node.name,
							"method": callable.get_method()
						})

	# Check all children recursively
	for child in search_node.get_children():
		if child != target_node: # Skip the target node itself
			_find_signals_targeting_node(child, target_node, signals_data)
