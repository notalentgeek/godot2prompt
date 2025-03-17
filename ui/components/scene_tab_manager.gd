@tool
extends RefCounted

# UI components for the scene tab
var scene_tab: VBoxContainer = null
var tree: Tree = null

func create_scene_tab() -> Control:
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
	help_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	scene_tab.add_child(help_label)

	# Add tree for scene hierarchy
	tree = Tree.new()
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.custom_minimum_size = Vector2(0, 250)
	tree.allow_rmb_select = false
	tree.select_mode = Tree.SELECT_MULTI
	scene_tab.add_child(tree)

	return scene_tab

# Get the tree for external usage
func get_tree() -> Tree:
	return tree

# Clear the tree for reuse
func clear_tree() -> void:
	if tree:
		tree.clear()
