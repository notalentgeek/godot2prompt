@tool
extends BaseController
class_name TreeSelectionController

"""
TreeSelectionController coordinates between the tree selection model and view.
It manages the tree selection logic and updates the model based on user interactions.
"""

func _init():
	"""
	Initialize the controller by creating model and view instances.
	"""
	super._init()
	_model = TreeSelectionModel.new()
	_view = TreeSelectionView.new(self)

func initialize(tree_control: Tree) -> void:
	"""
	Initialize with the tree control to manage.

	Args:
		tree_control: The Tree control instance
	"""
	_view.initialize(tree_control)

func initialize_tree_with_root(root_node: Node) -> void:
	"""
	Initialize the tree with the given root node.

	Args:
		root_node: The root node to display in the tree
	"""
	# Update the model
	_model.set_current_root(root_node)
	_model.clear_items()

	# Update the view
	_view.populate_tree_with_root(root_node)

func register_node_item(node: Node, item) -> void:
	"""
	Register a mapping between a node and its tree item.

	Args:
		node: The scene node
		item: The TreeItem representing the node
	"""
	_model.register_node_item(node, item)

func find_highest_selected_node() -> Node:
	"""
	Find the highest selected node in the hierarchy.

	Returns:
		The highest selected node, or null if none is selected
	"""
	var root_item = _view.get_root_item()
	if not root_item:
		return null

	# Create a callable that checks if an item is selected
	var is_selected_func = Callable(_view, "check_if_item_selected")

	return _model.find_highest_selected_node(root_item, is_selected_func)

func on_selection_changed() -> void:
	"""
	Handle changes in the tree selection.
	"""
	# In a more complex implementation, this would update the model
	# and potentially trigger other actions
	pass
