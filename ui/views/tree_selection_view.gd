@tool
extends RefCounted
class_name TreeSelectionView

"""
TreeSelectionView handles the visual representation of the tree selection.
It manages the Tree control visual state and updates.
"""

# UI references
var _controller = null
var _tree: Tree = null
var _root_item: TreeItem = null

func _init(controller):
	"""
	Initialize the tree selection view with a reference to its controller.

	Args:
		controller: The TreeSelectionController instance
	"""
	_controller = controller

func initialize(tree_control: Tree) -> void:
	"""
	Initialize with the tree control to manage.

	Args:
		tree_control: The Tree control instance
	"""
	_tree = tree_control

	# Connect to tree signals
	if _tree:
		_tree.connect("item_selected", Callable(self, "_on_item_selected"))

func populate_tree_with_root(root_node: Node) -> void:
	"""
	Populate the tree with the given root node and its children.

	Args:
		root_node: The root node to populate the tree with
	"""
	if not _tree:
		return

	# Clear the tree
	_tree.clear()

	# Create root item
	_root_item = _tree.create_item()
	_root_item.set_text(0, root_node.name + " (" + root_node.get_class() + ")")
	_root_item.set_metadata(0, root_node)

	# Register the root node-item mapping
	_controller.register_node_item(root_node, _root_item)

	# Recursively add all children
	_add_children_to_tree(root_node, _root_item)

	# Expand the root by default
	_root_item.set_collapsed(false)

	# Select the root by default
	_root_item.select(0)
	_select_children(_root_item)

func _add_children_to_tree(node: Node, parent_item: TreeItem) -> void:
	"""
	Recursively add children to the tree.

	Args:
		node: The parent node
		parent_item: The TreeItem for the parent node
	"""
	for child in node.get_children():
		var item = _tree.create_item(parent_item)
		item.set_text(0, child.name + " (" + child.get_class() + ")")
		item.set_metadata(0, child)

		# Register the node-item mapping
		_controller.register_node_item(child, item)

		# Recursively add children
		_add_children_to_tree(child, item)

func _on_item_selected() -> void:
	"""
	Handle tree item selection changes.
	"""
	var selected_item = _tree.get_selected()

	# Toggle children selection based on parent
	if selected_item.is_selected(0):
		_select_children(selected_item)
	else:
		_deselect_children(selected_item)

	# Notify the controller of selection change
	_controller.on_selection_changed()

func _select_children(item: TreeItem) -> void:
	"""
	Recursively select all children of an item.

	Args:
		item: The parent TreeItem
	"""
	var child = item.get_first_child()
	while child:
		child.select(0)
		_select_children(child)
		child = child.get_next()

func _deselect_children(item: TreeItem) -> void:
	"""
	Recursively deselect all children of an item.

	Args:
		item: The parent TreeItem
	"""
	var child = item.get_first_child()
	while child:
		child.deselect(0)
		_deselect_children(child)
		child = child.get_next()

func get_root_item() -> TreeItem:
	"""
	Get the root TreeItem.

	Returns:
		The root TreeItem
	"""
	return _root_item

func check_if_item_selected(item: TreeItem) -> bool:
	"""
	Check if a TreeItem is selected.

	Args:
		item: The TreeItem to check

	Returns:
		True if the item is selected, false otherwise
	"""
	return item.is_selected(0)
