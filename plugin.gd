@tool
extends EditorPlugin

var menu: EditorInterface

func _enter_tree() -> void:
	menu = get_editor_interface()
	add_tool_menu_item("Export Scene Hierarchy", export_scene_hierarchy)

func _exit_tree() -> void:
	remove_tool_menu_item("Export Scene Hierarchy")

func export_scene_hierarchy() -> void:
	var root = menu.get_edited_scene_root()
	if root:
		var hierarchy_text = format_hierarchy(root, 0)
		var file = FileAccess.open("res://scene_hierarchy.txt", FileAccess.WRITE)
		file.store_string(hierarchy_text)
		file.close()
		print("Scene hierarchy exported to scene_hierarchy.txt")

func format_hierarchy(node: Node, depth: int) -> String:
	var indent = "  ".repeat(depth)
	var output = indent + "- " + node.name + " (" + node.get_class() + ")\n"

	for child in node.get_children():
		output += format_hierarchy(child, depth + 1)

	return output
