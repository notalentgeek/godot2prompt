@tool
extends RefCounted

# Extract relevant properties based on node type
func extract_node_properties(node: Node) -> Dictionary:
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
