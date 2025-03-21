@tool
extends RefCounted
class_name PropertiesExtractor

"""
PropertiesExtractor extracts relevant properties from different node types.
It extracts common properties that apply to all nodes, as well as specific properties
based on the node's type (2D, 3D, physics, etc.).
"""

# Property Keys
const PROPERTY_COLLISION_LAYER: String = "Collision Layer"
const PROPERTY_COLLISION_MASK: String = "Collision Mask"
const PROPERTY_CURRENT: String = "Current"
const PROPERTY_FOV: String = "FOV"
const PROPERTY_LAYOUT_MODE: String = "Layout Mode"
const PROPERTY_MODULATE: String = "Modulate"
const PROPERTY_POSITION: String = "Position"
const PROPERTY_ROTATION: String = "Rotation"
const PROPERTY_SCALE: String = "Scale"
const PROPERTY_SHAPE_TYPE: String = "Shape Type"
const PROPERTY_SIZE: String = "Size"
const PROPERTY_TEXT: String = "Text"
const PROPERTY_UNIQUE_NAME: String = "Unique Name"
const PROPERTY_VISIBLE: String = "Visible"
const PROPERTY_ZOOM: String = "Zoom"

func extract_node_properties(node: Node) -> Dictionary:
	"""
	Extracts relevant properties from a node based on its type.

	Args:
		node: The node to extract properties from

	Returns:
		Dictionary containing property name-value pairs
	"""
	var properties = {}

	# Extract common properties for all nodes
	_extract_common_properties(node, properties)

	# Extract type-specific properties
	if node is CanvasItem:
		_extract_canvas_item_properties(node, properties)

	if node is Node3D:
		_extract_node3d_properties(node, properties)

	if node is PhysicsBody2D or node is PhysicsBody3D:
		_extract_physics_body_properties(node, properties)

	if node is CollisionShape2D or node is CollisionShape3D:
		_extract_collision_shape_properties(node, properties)

	if node is Camera2D:
		_extract_camera2d_properties(node, properties)

	if node is Camera3D:
		_extract_camera3d_properties(node, properties)

	return properties

func _extract_common_properties(node: Node, properties: Dictionary) -> void:
	"""
	Extracts properties common to all node types.

	Args:
		node: The node to extract properties from
		properties: Dictionary to add properties to
	"""
	properties[PROPERTY_UNIQUE_NAME] = node.name

func _extract_canvas_item_properties(node: CanvasItem, properties: Dictionary) -> void:
	"""
	Extracts properties specific to CanvasItem nodes (2D nodes).

	Args:
		node: The CanvasItem node to extract properties from
		properties: Dictionary to add properties to
	"""
	properties[PROPERTY_POSITION] = node.position
	properties[PROPERTY_SCALE] = node.scale
	properties[PROPERTY_ROTATION] = node.rotation
	properties[PROPERTY_VISIBLE] = node.visible
	properties[PROPERTY_MODULATE] = node.modulate

	# Handle Control-specific properties
	if node is Control:
		_extract_control_properties(node, properties)

func _extract_control_properties(node: Control, properties: Dictionary) -> void:
	"""
	Extracts properties specific to Control nodes.

	Args:
		node: The Control node to extract properties from
		properties: Dictionary to add properties to
	"""
	properties[PROPERTY_SIZE] = node.size
	properties[PROPERTY_LAYOUT_MODE] = node.size_flags_horizontal

	# Check for text property (exists on buttons, labels, etc.)
	if "text" in node:
		properties[PROPERTY_TEXT] = node.text

func _extract_node3d_properties(node: Node3D, properties: Dictionary) -> void:
	"""
	Extracts properties specific to Node3D nodes (3D nodes).

	Args:
		node: The Node3D node to extract properties from
		properties: Dictionary to add properties to
	"""
	properties[PROPERTY_POSITION] = node.position
	properties[PROPERTY_SCALE] = node.scale
	properties[PROPERTY_ROTATION] = node.rotation
	properties[PROPERTY_VISIBLE] = node.visible

func _extract_physics_body_properties(node: Node, properties: Dictionary) -> void:
	"""
	Extracts properties specific to physics body nodes.

	Args:
		node: The physics body node to extract properties from
		properties: Dictionary to add properties to
	"""
	properties[PROPERTY_COLLISION_LAYER] = node.collision_layer
	properties[PROPERTY_COLLISION_MASK] = node.collision_mask

func _extract_collision_shape_properties(node: Node, properties: Dictionary) -> void:
	"""
	Extracts properties specific to collision shape nodes.

	Args:
		node: The collision shape node to extract properties from
		properties: Dictionary to add properties to
	"""
	# Extract shape type if a shape is defined
	if node.shape != null:
		properties[PROPERTY_SHAPE_TYPE] = node.shape.get_class()

func _extract_camera2d_properties(node: Camera2D, properties: Dictionary) -> void:
	"""
	Extracts properties specific to Camera2D nodes.

	Args:
		node: The Camera2D node to extract properties from
		properties: Dictionary to add properties to
	"""
	properties[PROPERTY_CURRENT] = node.current
	properties[PROPERTY_ZOOM] = node.zoom

func _extract_camera3d_properties(node: Camera3D, properties: Dictionary) -> void:
	"""
	Extracts properties specific to Camera3D nodes.

	Args:
		node: The Camera3D node to extract properties from
		properties: Dictionary to add properties to
	"""
	properties[PROPERTY_CURRENT] = node.current
	properties[PROPERTY_FOV] = node.fov
