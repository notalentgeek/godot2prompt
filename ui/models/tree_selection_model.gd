@tool
extends RefCounted
class_name TreeSelectionModel

"""
TreeSelectionModel represents the data model for the tree selection.
It maintains the mapping between tree items and scene nodes and tracks
the selection state.
"""

# Signals
signal selection_changed()

# Tree state
var _current_root: Node = null
var _node_items = {} # Dictionary to map Nodes to TreeItems

func set_current_root(root_node: Node) -> void:
	"""
	Set the current root node for the tree.

	Args:
		root_node: The root node of the scene
	"""
	_current_root = root_node
	_node_items.clear()
	emit_signal("selection_changed")

func get_current_root() -> Node:
	"""
	Get the current root node.

	Returns:
		The current root node
	"""
	return _current_root

func register_node_item(node: Node, item) -> void:
	"""
	Register a mapping between a node and its tree item.

	Args:
		node: The scene node
		item: The TreeItem representing the node
	"""
	_node_items[node] = item

func clear_items() -> void:
	"""
	Clear all node-item mappings.
	"""
	_node_items.clear()

func get_node_items() -> Dictionary:
	"""
	Get the dictionary mapping nodes to their tree items.

	Returns:
		Dictionary mapping Node objects to TreeItem objects
	"""
	return _node_items.duplicate()

func find_highest_selected_node(root_item, is_selected_func: Callable) -> Node:
	"""
	Find the highest selected node in the hierarchy.

	Args:
		root_item: The root TreeItem
		is_selected_func: Function to check if an item is selected

	Returns:
		The highest selected node, or null if none is selected
	"""
	# If root is selected, return the root node
	if is_selected_func.call(root_item):
		return _current_root

	# Otherwise search for the highest selected node
	return _find_highest_selected_in_children(root_item, is_selected_func)

func _find_highest_selected_in_children(item, is_selected_func: Callable) -> Node:
	"""
	Recursively find the highest selected node in children.

	Args:
		item: The parent TreeItem to check children of
		is_selected_func: Function to check if an item is selected

	Returns:
		The highest selected node, or null if none is selected
	"""
	var child = item.get_first_child()
	while child:
		if is_selected_func.call(child):
			return child.get_metadata(0)

		var selected_descendant = _find_highest_selected_in_children(child, is_selected_func)
		if selected_descendant:
			return selected_descendant

		child = child.get_next()

	return null
