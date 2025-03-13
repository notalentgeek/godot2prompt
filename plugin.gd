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
		# Create a confirmation dialog to ask about script inclusion
		var dialog = ConfirmationDialog.new()
		dialog.title = "Export Scene Hierarchy"
		dialog.dialog_text = "Include attached scripts in the export?"
		dialog.dialog_hide_on_ok = true
		dialog.get_ok_button().text = "Yes"
		
		# Add a "No" button that will export without scripts
		var no_button = dialog.add_button("No", true, "export_without_scripts")
		no_button.connect("pressed", Callable(self, "_on_export_without_scripts").bind(dialog, root))
		
		# Connect the default "OK" button to export with scripts
		dialog.connect("confirmed", Callable(self, "_on_export_with_scripts").bind(root))
		
		# Show the dialog
		menu.get_base_control().add_child(dialog)
		dialog.popup_centered()

func _on_export_with_scripts(root: Node) -> void:
	_perform_export(root, true)

func _on_export_without_scripts(dialog: Window, root: Node) -> void:
	dialog.hide()
	_perform_export(root, false)

func _perform_export(root: Node, include_scripts: bool) -> void:
	var hierarchy_text = format_hierarchy(root, 0, include_scripts)
	var file = FileAccess.open("res://scene_hierarchy.txt", FileAccess.WRITE)
	file.store_string(hierarchy_text)
	file.close()
	print("Scene hierarchy exported to scene_hierarchy.txt")

func format_hierarchy(node: Node, depth: int, include_scripts: bool = true) -> String:
	var indent = "  ".repeat(depth)
	var output = indent + "- " + node.name + " (" + node.get_class() + ")\n"
	
	if include_scripts and node.get_script():
		var script_text = "```gdscript\n" + node.get_script().get_source_code() + "\n```\n"
		output += indent + "  " + script_text.replace("\n", "\n" + indent + "  ") + "\n"
	
	for child in node.get_children():
		output += format_hierarchy(child, depth + 1, include_scripts)
	
	return output
