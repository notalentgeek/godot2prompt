@tool
extends RefCounted

# A class to represent node data
class NodeData:
	var name: String
	var type: String # Changed from class_name to avoid reserved keyword
	var script_code: String
	var children: Array
	var depth: int

	func _init(p_name: String, p_class: String, p_depth: int, p_script: String = ""):
		name = p_name
		type = p_class # Changed from class_name to avoid reserved keyword
		depth = p_depth
		script_code = p_script
		children = []

# Process the scene and gather data
func process_scene(root: Node) -> NodeData:
	return _process_node(root, 0)

# Recursively process each node
func _process_node(node: Node, depth: int) -> NodeData:
	var script_code = ""

	# Get script source code if available
	if node.get_script():
		script_code = node.get_script().get_source_code()

	# Create data for this node
	var node_data = NodeData.new(node.name, node.get_class(), depth, script_code)

	# Process all children
	for child in node.get_children():
		var child_data = _process_node(child, depth + 1)
		node_data.children.append(child_data)

	return node_data
