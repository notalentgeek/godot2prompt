@tool
extends EditorPlugin

var menu: EditorInterface
var ui_manager
var scene_manager
var tree_exporter
var code_exporter
var properties_exporter
var signal_exporter
var error_context_exporter
var project_config_exporter
var screenshot_exporter
var composite_exporter
var file_handler
var error_manager
var screenshot_manager

func _enter_tree() -> void:
    menu = get_editor_interface()

    # Initialize managers
    error_manager = load("res://addons/godot2prompt/core/managers/error_manager.gd").new()
    scene_manager = load("res://addons/godot2prompt/core/managers/scene_manager.gd").new()
    screenshot_manager = load("res://addons/godot2prompt/core/managers/screenshot_manager.gd").new()

    # Initialize UI components
    ui_manager = load("res://addons/godot2prompt/ui/export_dialog.gd").new()

    # Initialize exporters
    tree_exporter = load("res://addons/godot2prompt/core/exporters/tree_exporter.gd").new()
    code_exporter = load("res://addons/godot2prompt/core/exporters/code_exporter.gd").new()
    properties_exporter = load("res://addons/godot2prompt/core/exporters/properties_exporter.gd").new()
    signal_exporter = load("res://addons/godot2prompt/core/exporters/signal_exporter.gd").new()
    error_context_exporter = load("res://addons/godot2prompt/core/exporters/error_context_exporter.gd").new()
    project_config_exporter = load("res://addons/godot2prompt/core/exporters/project_config_exporter.gd").new()
    screenshot_exporter = load("res://addons/godot2prompt/core/exporters/screenshot_exporter.gd").new()
    composite_exporter = load("res://addons/godot2prompt/core/exporters/composite_exporter.gd").new()

    # Initialize IO handlers
    file_handler = load("res://addons/godot2prompt/core/io/file_handler.gd").new()

    # Setup error monitoring
    _setup_error_monitoring()

    # Setup tool menu with the new name
    add_tool_menu_item("Scene to Prompt", export_scene_hierarchy)

    # Add quick export option for convenience
    add_tool_menu_item("Quick Scene Export with Screenshot", quick_export_with_screenshot)

func _exit_tree() -> void:
    # Stop error monitoring
    error_manager.stop_monitoring()

    # Cleanup
    remove_tool_menu_item("Scene to Prompt")
    remove_tool_menu_item("Quick Scene Export with Screenshot")

    # No need to call queue_free on RefCounted objects - just set to null
    ui_manager = null
    scene_manager = null
    tree_exporter = null
    code_exporter = null
    properties_exporter = null
    signal_exporter = null
    error_context_exporter = null
    project_config_exporter = null
    screenshot_exporter = null
    composite_exporter = null
    file_handler = null
    error_manager = null
    screenshot_manager = null

# Setup error monitoring
func _setup_error_monitoring() -> void:
    # Add the timer to the scene tree
    var log_timer = error_manager.log_monitor.log_check_timer
    if log_timer and not log_timer.is_inside_tree():
        add_child(log_timer)
        log_timer.start()
        print("Godot2Prompt: Error monitoring started")

    # Add some sample errors for testing
    error_manager.add_error("Sample error: Missing node reference in PlayerController.gd:34")
    error_manager.add_error("Sample error: Type mismatch in Enemy.gd:127 - Expected int but got String")

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

# Quick export method that automatically includes screenshot
func quick_export_with_screenshot() -> void:
    var root = menu.get_edited_scene_root()
    if root:
        # Take screenshot
        var screenshot_path = screenshot_manager.capture_editor_screenshot(menu)

        # Default quick export options
        var include_properties = true
        var include_signals = false
        var include_scripts = false
        var include_errors = false
        var include_project_settings = false
        var enabled_setting_categories = []

        # Process the scene
        var node_data = scene_manager.process_scene(root, include_properties,
                                                  include_signals, [],
                                                  include_project_settings,
                                                  enabled_setting_categories,
                                                  screenshot_path)

        # Create a composite exporter for this export
        var exporter = load("res://addons/godot2prompt/core/exporters/composite_exporter.gd").new()

        # Add necessary exporters
        exporter.add_exporter(tree_exporter)

        if include_properties:
            exporter.add_exporter(properties_exporter)

        if screenshot_path != "":
            exporter.add_exporter(screenshot_exporter)

        # Generate the output
        var output_text = exporter.generate_output(node_data)

        # Save the file
        file_handler.save_to_file("res://scene_hierarchy.txt", output_text)

        # Show notification
        var notification = AcceptDialog.new()
        notification.title = "Export Complete"
        notification.dialog_text = "Scene hierarchy exported to scene_hierarchy.txt"
        if screenshot_path != "":
            notification.dialog_text += "\nScreenshot saved to " + screenshot_path

        # Add to the editor and show
        var base_control = menu.get_base_control()
        base_control.add_child(notification)
        notification.popup_centered()

        # Clean up the notification after it's closed
        notification.connect("confirmed", Callable(self, "_on_error_dialog_closed").bind(notification))
    else:
        # Show error message
        var error_dialog = AcceptDialog.new()
        error_dialog.title = "No Scene Open"
        error_dialog.dialog_text = "Please open a scene before using Quick Export."

        # Add to the editor and show
        var base_control = menu.get_base_control()
        base_control.add_child(error_dialog)
        error_dialog.popup_centered()

        # Clean up the dialog after it's closed
        error_dialog.connect("confirmed", Callable(self, "_on_error_dialog_closed").bind(error_dialog))

func _on_error_dialog_closed(dialog):
    # Remove the dialog from the scene tree
    if dialog and is_instance_valid(dialog):
        dialog.queue_free()

func _on_export_hierarchy(selected_node: Node, include_scripts: bool, include_properties: bool,
                         include_signals: bool, include_errors: bool, include_project_settings: bool,
                         enabled_setting_categories: Array = [], include_screenshot: bool = false) -> void:
    # Take screenshot if requested
    var screenshot_path = ""
    var screenshot_error = false

    if include_screenshot:
        # Try to capture screenshot, but don't let it break the export if it fails
        screenshot_path = screenshot_manager.capture_editor_screenshot(menu)
        if screenshot_path.is_empty():
            screenshot_error = true
            print("Godot2Prompt: Screenshot capture failed, but continuing with export")

    # Get the error log if needed
    var error_log = []
    if include_errors:
        error_log = error_manager.get_errors()

    # Process the scene to get the hierarchy starting from the selected node
    var node_data = scene_manager.process_scene(selected_node, include_properties,
                                              include_signals, error_log,
                                              include_project_settings,
                                              enabled_setting_categories,
                                              screenshot_path)

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

    if include_project_settings and not enabled_setting_categories.is_empty():
        exporter.add_exporter(project_config_exporter)

    if include_screenshot and screenshot_path != "":
        exporter.add_exporter(screenshot_exporter)

    # Generate the output
    var output_text = exporter.generate_output(node_data)

    # Save the file
    file_handler.save_to_file("res://scene_hierarchy.txt", output_text)

    # Show a notification
    var notification = AcceptDialog.new()
    notification.title = "Export Complete"
    notification.dialog_text = "Scene hierarchy exported to scene_hierarchy.txt"
    if include_screenshot and not screenshot_path.is_empty():
        notification.dialog_text += "\nScreenshot saved to " + screenshot_path
    elif include_screenshot and screenshot_error:
        notification.dialog_text += "\nScreenshot capture failed"

    # Add to the editor and show
    var base_control = menu.get_base_control()
    base_control.add_child(notification)
    notification.popup_centered()

    # Clean up the notification after it's closed
    notification.connect("confirmed", Callable(self, "_on_error_dialog_closed").bind(notification))

    print("Godot2Prompt: Scene hierarchy exported to scene_hierarchy.txt")
