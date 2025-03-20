@tool
extends EditorPlugin

var menu: EditorInterface
var ui_manager
var scene_manager # Changed from scene_processor
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
var export_timer: Timer = null
var completion_timer: Timer = null

func _enter_tree() -> void:
    menu = get_editor_interface()

    # Initialize components using your current directory structure
    error_manager = load("res://addons/godot2prompt/core/managers/error_manager.gd").new()
    # Fix the path to scene_manager
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

    # Create export timer
    export_timer = Timer.new()
    export_timer.one_shot = true
    export_timer.wait_time = 0.5
    export_timer.connect("timeout", Callable(self, "_on_export_timer_timeout"))
    add_child(export_timer)

    # Create completion timer (longer delay before hiding progress)
    completion_timer = Timer.new()
    completion_timer.one_shot = true
    completion_timer.wait_time = 2.0 # 2 seconds to see completion
    completion_timer.connect("timeout", Callable(self, "_on_completion_timer_timeout"))
    add_child(completion_timer)

    # Setup error monitoring
    _setup_error_monitoring()

    # Setup tool menu with the new name
    add_tool_menu_item("Scene to Prompt", export_scene_hierarchy)

    # Add quick export option for convenience
    add_tool_menu_item("Quick Scene Export with Screenshot", quick_export_with_screenshot)

    # Copy to clipboard is now in the export dialog itself, so we don't need a separate menu item
    # Removing: add_tool_menu_item("Copy Scene Hierarchy to Clipboard", copy_hierarchy_to_clipboard)

func _exit_tree() -> void:
    # Stop error monitoring
    error_manager.stop_monitoring()

    # Cleanup
    remove_tool_menu_item("Scene to Prompt")
    remove_tool_menu_item("Quick Scene Export with Screenshot")
    # Removing: remove_tool_menu_item("Copy Scene Hierarchy to Clipboard")

    # Remove the timers
    if export_timer:
        export_timer.queue_free()
        export_timer = null

    if completion_timer:
        completion_timer.queue_free()
        completion_timer = null

    # No need to call queue_free on RefCounted objects - just set to null
    ui_manager = null
    scene_manager = null # Changed from scene_processor
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
    if error_manager.log_monitor and error_manager.log_monitor.log_check_timer and not error_manager.log_monitor.log_check_timer.is_inside_tree():
        add_child(error_manager.log_monitor.log_check_timer)
        error_manager.log_monitor.log_check_timer.start()
        print("Godot2Prompt: Error monitoring started")

    # Add some sample errors for testing
    error_manager.add_error("Sample error: Missing node reference in PlayerController.gd:34")
    error_manager.add_error("Sample error: Type mismatch in Enemy.gd:127 - Expected int but got String")

# We're removing the standalone clipboard function since it's now in the export dialog
# Removing: func copy_hierarchy_to_clipboard() -> void { ... }

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
        # Initialize the dialog for quick export (to setup progress dialog)
        ui_manager.initialize(menu.get_base_control())

        # Show progress dialog
        ui_manager.show_progress()

        # Add a small delay before updating progress to ensure dialog is rendered
        await get_tree().create_timer(0.1).timeout

        ui_manager.update_progress(10, "Initializing quick export...")
        await get_tree().create_timer(0.1).timeout

        # Take screenshot
        ui_manager.update_progress(20, "Capturing screenshot...")
        await get_tree().create_timer(0.1).timeout
        var screenshot_path = screenshot_manager.capture_editor_screenshot(menu)

        # Default quick export options
        var include_properties = true
        var include_signals = false
        var include_scripts = false
        var include_errors = false
        var include_project_settings = false
        var enabled_setting_categories = []

        # Process the scene - Updated to use scene_manager instead of scene_processor
        ui_manager.update_progress(40, "Processing scene nodes...")
        await get_tree().create_timer(0.1).timeout
        var node_data = scene_manager.process_scene(root, include_properties,
                                                  include_signals, [],
                                                  include_project_settings,
                                                  enabled_setting_categories,
                                                  screenshot_path)

        # Create a composite exporter for this export
        ui_manager.update_progress(60, "Setting up exporters...")
        await get_tree().create_timer(0.1).timeout
        var exporter = load("res://addons/godot2prompt/core/exporters/composite_exporter.gd").new()

        # Add necessary exporters
        exporter.add_exporter(tree_exporter)

        if include_properties:
            exporter.add_exporter(properties_exporter)

        if screenshot_path != "":
            exporter.add_exporter(screenshot_exporter)

        # Generate the output
        ui_manager.update_progress(80, "Generating output text...")
        await get_tree().create_timer(0.1).timeout
        var output_text = exporter.generate_output(node_data)

        # Save the file
        ui_manager.update_progress(90, "Saving to file...")
        await get_tree().create_timer(0.1).timeout
        file_handler.save_to_file("res://scene_hierarchy.txt", output_text)

        # Complete progress
        ui_manager.update_progress(100, "Export complete!")

        # Use our timer to hide the progress dialog after a delay
        completion_timer.start()

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

func _on_export_timer_timeout():
    # Hide the progress dialog after the timer expires
    if ui_manager:
        ui_manager.hide_progress_dialog()

func _on_completion_timer_timeout():
    # Called when the completion timer expires (longer delay for 100%)
    if ui_manager:
        ui_manager.hide_progress_dialog()

func _on_export_hierarchy(selected_node: Node, include_scripts: bool, include_properties: bool,
                         include_signals: bool, include_errors: bool, include_project_settings: bool,
                         enabled_setting_categories: Array = [], include_screenshot: bool = false) -> void:
    # Show progress immediately when export starts
    ui_manager.show_progress()

    # Small delay to ensure the dialog is rendered
    get_tree().create_timer(0.1).timeout

    # Update progress - preparing for export
    ui_manager.update_progress(20, "Preparing export options...")

    # Add another small delay
    get_tree().create_timer(0.1).timeout

    # Take screenshot if requested - with better error handling
    var screenshot_path = ""
    var screenshot_error = false

    if include_screenshot:
        # Try to capture screenshot, but handle all errors
        ui_manager.update_progress(30, "Creating scene visualization...")

        # Use a deferred call to prevent errors during UI updates
        call_deferred("_capture_screenshot_deferred", include_scripts, include_properties,
                     include_signals, include_errors, include_project_settings,
                     enabled_setting_categories, selected_node)
        return
    else:
        # Proceed with export without screenshot
        _continue_export_without_screenshot(selected_node, include_scripts, include_properties,
                     include_signals, include_errors, include_project_settings,
                     enabled_setting_categories)

# New method to handle screenshot capture with deferred calling
func _capture_screenshot_deferred(include_scripts: bool, include_properties: bool,
                                include_signals: bool, include_errors: bool,
                                include_project_settings: bool,
                                enabled_setting_categories: Array, selected_node: Node) -> void:
    # Safely capture screenshot
    var screenshot_path = ""
    var screenshot_error = false

    screenshot_path = screenshot_manager.capture_editor_screenshot(menu)
    if screenshot_path.is_empty():
        screenshot_error = true

    # Continue with the rest of the export process
    _continue_export_with_screenshot(selected_node, include_scripts, include_properties,
                 include_signals, include_errors, include_project_settings,
                 enabled_setting_categories, screenshot_path, screenshot_error)

# New method to handle export continuation with screenshot
func _continue_export_with_screenshot(selected_node: Node, include_scripts: bool, include_properties: bool,
                                    include_signals: bool, include_errors: bool,
                                    include_project_settings: bool,
                                    enabled_setting_categories: Array,
                                    screenshot_path: String, screenshot_error: bool) -> void:
    # Continue with export process
    _continue_export_without_screenshot(selected_node, include_scripts, include_properties,
                 include_signals, include_errors, include_project_settings,
                 enabled_setting_categories, screenshot_path)

# New method to handle export without screenshot
func _continue_export_without_screenshot(selected_node: Node, include_scripts: bool, include_properties: bool,
                                       include_signals: bool, include_errors: bool,
                                       include_project_settings: bool,
                                       enabled_setting_categories: Array,
                                       screenshot_path: String = "") -> void:
    # Get the error log if needed
    var error_log = []
    if include_errors:
        ui_manager.update_progress(40, "Collecting error logs...")
        await get_tree().create_timer(0.1).timeout
        error_log = error_manager.get_errors()

    # Process the scene to get the hierarchy starting from the selected node
    ui_manager.update_progress(50, "Processing scene nodes...")
    await get_tree().create_timer(0.1).timeout
    var node_data = null

    # Try to process scene with error handling - Update to use scene_manager
    if scene_manager != null and scene_manager.has_method("process_scene") and selected_node != null:
        node_data = scene_manager.process_scene(selected_node, include_properties,
                                                include_signals, error_log,
                                                include_project_settings,
                                                enabled_setting_categories,
                                                screenshot_path)

    if node_data == null:
        ui_manager.update_progress(100, "Export failed - could not process scene")
        ui_manager.finalize_export()
        completion_timer.start()

        # Show error notification
        var error_notification = AcceptDialog.new()
        error_notification.title = "Export Error"
        error_notification.dialog_text = "Failed to process scene data for export."
        var base_control = menu.get_base_control()
        base_control.add_child(error_notification)
        error_notification.popup_centered()
        error_notification.connect("confirmed", Callable(self, "_on_error_dialog_closed").bind(error_notification))
        return

    # Create a fresh composite exporter for this export
    ui_manager.update_progress(60, "Setting up exporters...")
    await get_tree().create_timer(0.1).timeout
    var exporter = load("res://addons/godot2prompt/core/exporters/composite_exporter.gd").new()

    # The tree exporter is always included for the base structure
    exporter.add_exporter(tree_exporter)

    # Add other exporters based on options
    if include_properties and properties_exporter != null:
        exporter.add_exporter(properties_exporter)

    if include_signals and signal_exporter != null:
        exporter.add_exporter(signal_exporter)

    if include_scripts and code_exporter != null:
        exporter.add_exporter(code_exporter)

    if include_errors and error_context_exporter != null:
        exporter.add_exporter(error_context_exporter)

    if include_project_settings and not enabled_setting_categories.is_empty() and project_config_exporter != null:
        exporter.add_exporter(project_config_exporter)

    if screenshot_path != "" and screenshot_exporter != null:
        exporter.add_exporter(screenshot_exporter)

    # Generate the output
    ui_manager.update_progress(80, "Generating output text...")
    await get_tree().create_timer(0.1).timeout
    var output_text = exporter.generate_output(node_data)

    # Save the file
    ui_manager.update_progress(90, "Saving to file...")
    await get_tree().create_timer(0.1).timeout
    file_handler.save_to_file("res://scene_hierarchy.txt", output_text)

    # Finalize progress
    ui_manager.finalize_export()

    # Start the timer to hide the progress dialog after a longer delay
    completion_timer.start()

    # Show a notification
    var notification = AcceptDialog.new()
    notification.title = "Export Complete"
    notification.dialog_text = "Scene hierarchy exported to scene_hierarchy.txt"
    if screenshot_path != "":
        notification.dialog_text += "\nScene visualization saved to " + screenshot_path

    # Add to the editor and show
    var base_control = menu.get_base_control()
    base_control.add_child(notification)
    notification.popup_centered()

    # Clean up the notification after it's closed
    notification.connect("confirmed", Callable(self, "_on_error_dialog_closed").bind(notification))
