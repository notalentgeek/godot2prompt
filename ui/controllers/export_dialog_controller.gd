@tool
extends BaseController
class_name ExportDialogController

"""
ExportDialogController coordinates between the export dialog model and view.
It handles user interactions and forwards data between the model and view.
"""

# Constants - Paths
const EXPORT_DIALOG_MODEL_PATH: String = "res://addons/godot2prompt/ui/models/export_dialog_model.gd"
const EXPORT_DIALOG_VIEW_PATH: String = "res://addons/godot2prompt/ui/views/export_dialog_view.gd"
const PROGRESS_DIALOG_CONTROLLER_PATH: String = "res://addons/godot2prompt/ui/controllers/progress_dialog_controller.gd"

# Constants - Settings
const MAX_CLIPBOARD_LINES: int = 1000 # Maximum number of lines for clipboard copy

# Properties
var _options_tab_controller = null
var _progress_dialog_controller = null
var _scene_tab_controller = null
var _tree_selection_controller = null

# Signals
signal export_hierarchy(selected_node, include_scripts, include_properties, include_signals, include_errors, include_project_settings, enabled_setting_categories, include_screenshot)
signal export_progress(progress, message)

func _init():
    """
    Initialize the controller by creating model and view instances.
    """
    super._init()

    var ExportDialogModel = load(EXPORT_DIALOG_MODEL_PATH)
    var ExportDialogView = load(EXPORT_DIALOG_VIEW_PATH)

    _model = ExportDialogModel.new()
    _view = ExportDialogView.new(self)

    # Initialize progress dialog controller
    var ProgressDialogController = load(PROGRESS_DIALOG_CONTROLLER_PATH)
    _progress_dialog_controller = ProgressDialogController.new()

    # Connect model signals
    _model.export_requested.connect(_on_export_requested)

func initialize(parent_control: Control) -> void:
    """
    Initialize the controller with the parent control.

    Args:
        parent_control: The parent control to add the dialog to
    """
    _view.initialize(parent_control)
    _progress_dialog_controller.initialize(parent_control)

func show_dialog(root_node: Node) -> void:
    """
    Show the export dialog with the given root node.

    Args:
        root_node: The root node to display in the dialog
    """
    _model.set_current_root(root_node)
    _view.show_dialog(root_node)

func set_tree_selection_controller(controller) -> void:
    """
    Set the tree selection controller.

    Args:
        controller: The tree selection controller
    """
    _tree_selection_controller = controller

func get_tree_selection_controller():
    """
    Get the tree selection controller.

    Returns:
        The tree selection controller
    """
    return _tree_selection_controller

func set_tab_controllers(scene_tab_controller, options_tab_controller) -> void:
    """
    Set the tab controllers.

    Args:
        scene_tab_controller: The scene tab controller
        options_tab_controller: The options tab controller
    """
    _scene_tab_controller = scene_tab_controller
    _options_tab_controller = options_tab_controller

func _on_export_confirmed() -> void:
    """
    Handle export confirmation.
    """
    print("Export confirmed, showing progress dialog")
    _progress_dialog_controller.show_progress()

    # Get options from the options tab
    var export_options = _options_tab_controller.get_export_options()

    # Debug print
    print("Godot2Prompt: Screenshot option: " + str(export_options.get("include_screenshot", "not found")))

    _model.set_export_options(export_options)

    # Find the highest selected node in the hierarchy
    var selected_node = _tree_selection_controller.find_highest_selected_node()
    _model.set_selected_node(selected_node)

    if selected_node:
        # Request export through the model
        _model.request_export()
    else:
        _progress_dialog_controller.hide_progress()
        _view.show_error_dialog("No Node Selected", "Please select a node in the scene tree first.")

func _on_export_requested(export_data: Dictionary) -> void:
    """
    Handle export request from the model.

    Args:
        export_data: Dictionary containing export configuration
    """
    # Emit signal for external handlers
    emit_signal("export_hierarchy",
        export_data.selected_node,
        export_data.include_scripts,
        export_data.include_properties,
        export_data.include_signals,
        export_data.include_errors,
        export_data.include_project_settings,
        export_data.enabled_setting_categories,
        export_data.include_screenshot)

func _on_custom_action(action_name: String) -> void:
    """
    Handle custom dialog actions.

    Args:
        action_name: The name of the action
    """
    if action_name == "copy_to_clipboard":
        print("Copy to clipboard button pressed")
        _handle_copy_to_clipboard()

func _handle_copy_to_clipboard() -> void:
    """
    Handle copying the export data to clipboard.
    Checks if the content is too large and warns the user if it exceeds the threshold.
    """
    # Get options from the options tab
    var export_options = _options_tab_controller.get_export_options()
    _model.set_export_options(export_options)

    # Find the highest selected node in the hierarchy
    var selected_node = _tree_selection_controller.find_highest_selected_node()
    _model.set_selected_node(selected_node)

    if selected_node:
        # Show a processing notification
        var notification = _view.show_clipboard_notification("Processing scene export for clipboard...")

        # Prepare export data
        var export_data = _model.prepare_export_data()

        # Process the export
        var output_text = _model.process_export_to_clipboard(export_data)

        # Count the number of lines
        var line_count = output_text.split("\n").size()

        # Check if content is too large
        if line_count > MAX_CLIPBOARD_LINES:
            # Clean up the processing notification
            _clean_up_notification(notification)

            # Show warning dialog
            _view.show_clipboard_size_warning(line_count, MAX_CLIPBOARD_LINES)
        else:
            # Copy to clipboard
            DisplayServer.clipboard_set(output_text)

            # Update notification
            notification.dialog_text = "Scene export copied to clipboard!"
    else:
        _view.show_error_dialog("No Node Selected", "Please select a node in the scene tree first.")

func _on_canceled() -> void:
    """
    Handle dialog cancellation.
    """
    _model.set_current_root(null)
    _model.set_selected_node(null)

func _clean_up_notification(notification) -> void:
    """
    Clean up a notification dialog.

    Args:
        notification: The notification dialog to clean up
    """
    if notification and is_instance_valid(notification):
        notification.queue_free()

# Progress dialog forwarding methods
func update_progress(progress: int, message: String) -> void:
    """
    Update the progress dialog.

    Args:
        progress: The progress value (0-100)
        message: The progress message
    """
    _progress_dialog_controller.update_progress(progress, message)

func show_progress() -> void:
    """
    Show the progress dialog.
    """
    _progress_dialog_controller.show_progress()

func hide_progress() -> void:
    """
    Hide the progress dialog.
    """
    _progress_dialog_controller.hide_progress()

func finalize_export() -> void:
    """
    Finalize the export process.
    """
    _progress_dialog_controller.update_progress(100, "Export completed!")
