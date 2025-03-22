@tool
extends RefCounted
class_name SceneTabView

"""
SceneTabView creates and manages the UI for the scene tab.
It handles the visual representation of the scene hierarchy.
"""

# Constants
const HELP_TEXT_COLOR: Color = Color(0.7, 0.7, 0.7)
const TREE_MIN_HEIGHT: int = 250

# UI components
var _controller = null
var scene_tab: VBoxContainer = null
var tree: Tree = null

func _init(controller):
	"""
	Initialize the scene tab view with a reference to its controller.

	Args:
		controller: The SceneTabController instance
	"""
	_controller = controller

func create_view() -> Control:
	"""
	Create and configure the scene tab view UI.

	Returns:
		The root control for the scene tab
	"""
	# Create scene tab container
	scene_tab = VBoxContainer.new()
	scene_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Add dialog header label
	var header_label = Label.new()
	header_label.text = "Select nodes to include in export:"
	scene_tab.add_child(header_label)

	# Add help text
	var help_label = Label.new()
	help_label.text = "Selecting a node will automatically include all its children"
	help_label.add_theme_color_override("font_color", HELP_TEXT_COLOR)
	scene_tab.add_child(help_label)

	# Add tree for scene hierarchy
	tree = Tree.new()
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.custom_minimum_size = Vector2(0, TREE_MIN_HEIGHT)
	tree.allow_rmb_select = false
	tree.select_mode = Tree.SELECT_MULTI
	scene_tab.add_child(tree)

	return scene_tab

func get_tree() -> Tree:
	"""
	Get the tree control for external usage.

	Returns:
		The Tree control instance
	"""
	return tree

func clear_tree() -> void:
	"""
	Clear the tree for reuse.
	"""
	if tree:
		tree.clear()
