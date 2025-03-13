@tool
extends RefCounted

# A class to represent node data
class NodeData:
	var name: String
	var type: String # Changed from class_name to avoid reserved keyword
	var script_code: String
	var properties: Dictionary
	var children: Array
	var depth: int

	func _init(p_name: String, p_class: String, p_depth: int, p_script: String = "", p_properties: Dictionary = {}):
		name = p_name
		type = p_class
		depth = p_depth
		script_code = p_script
		properties = p_properties
		children = []

# Process the scene and gather data
func process_scene(root: Node, include_properties: bool = false) -> NodeData:
	return _process_node(root, 0, include_properties)

# Recursively process each node
func _process_node(node: Node, depth: int, include_properties: bool) -> NodeData:
	var script_code = ""
	var properties = {}

	# Get script source code if available
	if node.get_script():
		script_code = node.get_script().get_source_code()

	# Extract properties if requested
	if include_properties:
		properties = _extract_node_properties(node)

	# Create data for this node
	var node_data = NodeData.new(node.name, node.get_class(), depth, script_code, properties)

	# Process all children
	for child in node.get_children():
		var child_data = _process_node(child, depth + 1, include_properties)
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

	# Spatial properties (3D nodes)
	if node is Node3D:
		properties["Position"] = node.position
		properties["Scale"] = node.scale
		properties["Rotation"] = node.rotation
		properties["Visible"] = node.visible

	# PhysicsBody-specific properties
	if node is PhysicsBody2D or node is PhysicsBody3D:
		properties["Collision Layer"] = node.collision_layer
		properties["Collision Mask"] = node.collision_mask

	# CollisionShape properties
	if node is CollisionShape2D:
		if node.shape != null:
			properties["Shape Type"] = node.shape.get_class()

	if node is CollisionShape3D:
		if node.shape != null:
			properties["Shape Type"] = node.shape.get_class()

	# Camera properties
	if node is Camera2D:
		properties["Current"] = node.current
		properties["Zoom"] = node.zoom

	if node is Camera3D:
		properties["Current"] = node.current
		properties["FOV"] = node.fov

	# Add more node type specific properties here

	return properties
