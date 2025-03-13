@tool
extends EditorPlugin

var menu: EditorInterface
var ui_manager
var scene_processor
var tree_exporter
var code_exporter
var properties_exporter
var file_handler

func _enter_tree() -> void:
	menu = get_editor_interface()

	# Initialize components using load instead of preload
	ui_manager = load("res://addons/godot2prompt/ui/export_dialog.gd").new()
	scene_processor = load("res://addons/godot2prompt/core/scene_processor.gd").new()
	tree_exporter = load("res://addons/godot2prompt/core/exporters/tree_exporter.gd").new()
	code_exporter = load("res://addons/godot2prompt/core/exporters/code_exporter.gd").new()
	properties_exporter = load("res://addons/godot2prompt/core/exporters/properties_exporter.gd").new()
	file_handler = load("res://addons/godot2prompt/core/io/file_handler.gd").new()

	# Setup tool menu with a reference to the method (safer approach)
	add_tool_menu_item("Export Scene Hierarchy", export_scene_hierarchy)

func _exit_tree() -> void:
	# Cleanup
	remove_tool_menu_item("Export Scene Hierarchy")

	# Free components
	if ui_manager:
		ui_manager.queue_free()

	ui_manager = null
	scene_processor = null
	tree_exporter = null
	code_exporter = null
	properties_exporter = null
	file_handler = null

# The menu will call this method
func export_scene_hierarchy() -> void:
	var root = menu.get_edited_scene_root()
	if root:
		# Initialize the dialog with the root node
		ui_manager.initialize(menu.get_base_control())

		# Connect signals
		if not ui_manager.is_connected("export_with_scripts", Callable(self, "_on_export_with_scripts")):
			ui_manager.connect("export_with_scripts", Callable(self, "_on_export_with_scripts"))

		if not ui_manager.is_connected("export_without_scripts", Callable(self, "_on_export_without_scripts")):
			ui_manager.connect("export_without_scripts", Callable(self, "_on_export_without_scripts"))

		ui_manager.show_dialog(root)

func _on_export_with_scripts(root: Node, include_properties: bool) -> void:
	_perform_export(root, true, include_properties)

func _on_export_without_scripts(root: Node, include_properties: bool) -> void:
	_perform_export(root, false, include_properties)

func _perform_export(root: Node, include_scripts: bool, include_properties: bool) -> void:
	# Process the scene to get the hierarchy
	var node_data = scene_processor.process_scene(root, include_properties)

	# Format the hierarchy based on export options
	var output_text = ""

	if include_scripts and include_properties:
		# Create a combined output with both scripts and properties
		output_text = _generate_combined_output(node_data)
	elif include_scripts:
		output_text = code_exporter.generate_output(node_data)
	elif include_properties:
		output_text = properties_exporter.generate_output(node_data)
	else:
		output_text = tree_exporter.generate_output(node_data)

	# Save the file
	file_handler.save_to_file("res://scene_hierarchy.txt", output_text)
	print("Scene hierarchy exported to scene_hierarchy.txt")

# Generate a combined output with both scripts and properties
func _generate_combined_output(node_data) -> String:
	var combined_exporter = load("res://addons/godot2prompt/core/exporters/code_exporter.gd").new()
	var output = combined_exporter.generate_output(node_data)

	# If we want to implement a specific combined exporter in the future,
	# we can create a new exporter class instead of this method

	return output
