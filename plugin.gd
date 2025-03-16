@tool
extends EditorPlugin

var menu: EditorInterface
var ui_manager
var scene_processor
var tree_exporter
var code_exporter
var properties_exporter
var signal_exporter
var error_context_exporter
var project_config_exporter
var composite_exporter
var file_handler
var error_logger

func _enter_tree() -> void:
    menu = get_editor_interface()

    # Initialize components
    ui_manager = load("res://addons/godot2prompt/ui/export_dialog.gd").new()
    scene_processor = load("res://addons/godot2prompt/core/scene_processor.gd").new()
    tree_exporter = load("res://addons/godot2prompt/core/exporters/tree_exporter.gd").new()
    code_exporter = load("res://addons/godot2prompt/core/exporters/code_exporter.gd").new()
    properties_exporter = load("res://addons/godot2prompt/core/exporters/properties_exporter.gd").new()
    signal_exporter = load("res://addons/godot2prompt/core/exporters/signal_exporter.gd").new()
    error_context_exporter = load("res://addons/godot2prompt/core/exporters/error_context_exporter.gd").new()
    project_config_exporter = load("res://addons/godot2prompt/core/exporters/project_config_exporter.gd").new()
    composite_exporter = load("res://addons/godot2prompt/core/exporters/composite_exporter.gd").new()
    file_handler = load("res://addons/godot2prompt/core/io/file_handler.gd").new()
    error_logger = load("res://addons/godot2prompt/core/error_logger.gd").new()

    # Setup error monitoring
    _setup_error_monitoring()

    # Setup tool menu with the new name
    add_tool_menu_item("Scene to Prompt", export_scene_hierarchy)

func _exit_tree() -> void:
    # Stop error monitoring
    error_logger.stop_monitoring()

    # Cleanup
    remove_tool_menu_item("Scene to Prompt")

    # No need to call queue_free on RefCounted objects - just set to null
    ui_manager = null
    scene_processor = null
    tree_exporter = null
    code_exporter = null
    properties_exporter = null
    signal_exporter = null
    error_context_exporter = null
    project_config_exporter = null
    composite_exporter = null
    file_handler = null
    error_logger = null

# Setup error monitoring
func _setup_error_monitoring() -> void:
    # Add the timer to the scene tree
    if error_logger.log_check_timer and not error_logger.log_check_timer.is_inside_tree():
        add_child(error_logger.log_check_timer)
        error_logger.log_check_timer.start()
        print("Godot2Prompt: Error monitoring started")

    # Add some sample errors for testing
    error_logger.add_error("Sample error: Missing node reference in PlayerController.gd:34")
    error_logger.add_error("Sample error: Type mismatch in Enemy.gd:127 - Expected int but got String")

# The menu will call this method
func export_scene_hierarchy() -> void:
    var root = menu.get_edited_scene_root()
    if root:
        # Initialize the dialog with the root node
        ui_manager.initialize(menu.get_base_control())

        # Connect signal for export
        if not ui_manager.is_connected("export_hierarchy", Callable(self, "_on_export_hierarchy")):
            ui_manager.connect("export_hierarchy", Callable(self, "_on_export_hierarchy"))

        ui_manager.show_dialog(root)
    else:
        # Show a user-friendly error message when no scene is open
        var error_dialog = AcceptDialog.new()
        error_dialog.title = "No Scene Open"
        error_dialog.dialog_text = "Please open a scene before using Scene to Prompt.\n\nThis tool exports the hierarchy of an open scene."

        # Add to the editor and show
        var base_control = menu.get_base_control()
        base_control.add_child(error_dialog)
        error_dialog.popup_centered()

        # Clean up the dialog after it's closed
        error_dialog.connect("confirmed", Callable(self, "_on_error_dialog_closed").bind(error_dialog))
        error_dialog.connect("canceled", Callable(self, "_on_error_dialog_closed").bind(error_dialog))

func _on_error_dialog_closed(dialog):
    # Remove the dialog from the scene tree
    if dialog and is_instance_valid(dialog):
        dialog.queue_free()

func _on_export_hierarchy(selected_node: Node, include_scripts: bool, include_properties: bool,
                         include_signals: bool, include_errors: bool, include_project_settings: bool) -> void:
    # Get the error log if needed
    var error_log = []
    if include_errors:
        error_log = error_logger.get_errors()

    # Process the scene to get the hierarchy starting from the selected node
    var node_data = scene_processor.process_scene(selected_node, include_properties,
                                                 include_signals, error_log,
                                                 include_project_settings)

    # Create a fresh composite exporter for this export
    var exporter = load("res://addons/godot2prompt/core/exporters/composite_exporter.gd").new()

    # The tree exporter is always included for the base structure
    exporter.add_exporter(tree_exporter)

    # Add other exporters based on options
    if include_properties:
        exporter.add_exporter(properties_exporter)

    if include_signals:
        exporter.add_exporter(signal_exporter)

    if include_scripts:
        exporter.add_exporter(code_exporter)

    if include_errors:
        exporter.add_exporter(error_context_exporter)

    if include_project_settings:
        exporter.add_exporter(project_config_exporter)

    # Generate the output
    var output_text = exporter.generate_output(node_data)

    # Save the file
    file_handler.save_to_file("res://scene_hierarchy.txt", output_text)
    print("Scene hierarchy exported to scene_hierarchy.txt")
