@tool
extends RefCounted

# Tree references and state
var tree: Tree = null
var root_item: TreeItem = null
var node_items = {} # Dictionary to map TreeItems to Nodes
var current_root: Node = null

func initialize(tree_control: Tree) -> void:
	tree = tree_control
	tree.connect("item_selected", Callable(self, "_on_item_selected"))

func initialize_tree_with_root(root_node: Node) -> void:
	current_root = root_node
	node_items.clear()

	# Create root item
	root_item = tree.create_item()
	root_item.set_text(0, root_node.name + " (" + root_node.get_class() + ")")
	root_item.set_metadata(0, root_node)
	node_items[root_node] = root_item

	# Recursively add all children
	_add_children_to_tree(root_node, root_item)

	# Expand the root by default
	root_item.set_collapsed(false)

	# Select the root by default
	root_item.select(0)
	_select_children(root_item)

func _add_children_to_tree(node: Node, parent_item: TreeItem) -> void:
	for child in node.get_children():
		var item = tree.create_item(parent_item)
		item.set_text(0, child.name + " (" + child.get_class() + ")")
		item.set_metadata(0, child)
		node_items[child] = item

		# Recursively add children
		_add_children_to_tree(child, item)

func _on_item_selected() -> void:
	var selected_item = tree.get_selected()

	# Toggle children selection based on parent
	if selected_item.is_selected(0):
		_select_children(selected_item)
	else:
		_deselect_children(selected_item)

func _select_children(item: TreeItem) -> void:
	var child = item.get_first_child()
	while child:
		child.select(0)
		_select_children(child)
		child = child.get_next()

func _deselect_children(item: TreeItem) -> void:
	var child = item.get_first_child()
	while child:
		child.deselect(0)
		_deselect_children(child)
		child = child.get_next()

func find_highest_selected_node() -> Node:
	# Start with the root item
	var item = root_item

	# If root is selected, return the root node
	if item.is_selected(0):
		return current_root

	# Otherwise search for the highest selected node
	return _find_highest_selected_in_children(item)

func _find_highest_selected_in_children(item: TreeItem) -> Node:
	var child = item.get_first_child()
	while child:
		if child.is_selected(0):
			return child.get_metadata(0)

		var selected_descendant = _find_highest_selected_in_children(child)
		if selected_descendant:
			return selected_descendant

		child = child.get_next()

	return null
