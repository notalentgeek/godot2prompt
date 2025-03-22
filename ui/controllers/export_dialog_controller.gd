@tool
extends BaseController
class_name ExportDialogController

# Constants - Script Paths
const EXPORT_DIALOG_MODEL_PATH: String = "res://addons/godot2prompt/ui/models/export_dialog_model.gd"
const EXPORT_DIALOG_VIEW_PATH: String = "res://addons/godot2prompt/ui/views/export_dialog_view.gd"
const PROGRESS_DIALOG_CONTROLLER_PATH: String = "res://addons/godot2prompt/ui/controllers/progress_dialog_controller.gd"
const SCENE_TAB_CONTROLLER_PATH: String = "res://addons/godot2prompt/ui/controllers/scene_tab_controller.gd"
const OPTIONS_TAB_CONTROLLER_PATH: String = "res://addons/godot2prompt/ui/controllers/options_tab_controller.gd"
const TREE_SELECTION_CONTROLLER_PATH: String = "res://addons/godot2prompt/ui/controllers/tree_selection_controller.gd"

# Signals
signal export_hierarchy(
	selected_node,
	include_scripts,
	include_properties,
	include_signals,
	include_errors,
	include_project_settings,
	enabled_setting_categories,
	include_screenshot
)
signal export_progress(progress, message)

# Properties - Controllers
var _options_tab_controller = null
var _progress_dialog_controller = null
var _scene_tab_controller = null
var _tree_selection_controller = null

func _init() -> void:
    super._init()

    # Initialize model
    _initialize_model()

func _initialize_model() -> void:
    var model_script = load(EXPORT_DIALOG_MODEL_PATH)
    if model_script:
        _model = model_script.new()
        if _model:
            _model.export_requested.connect(_on_export_requested)
        else:
            push_error("Failed to instantiate ExportDialogModel")
    else:
        push_error("Failed to load ExportDialogModel from: " + EXPORT_DIALOG_MODEL_PATH)

func initialize(parent_control: Control) -> void:
    if not parent_control:
        push_error("Parent control is null in ExportDialogController.initialize")
        return

    # First create all supporting controllers
    _create_supporting_controllers()

    # Initialize the progress dialog controller
    _initialize_progress_controller(parent_control)

    # Then create and initialize the view
    _initialize_view(parent_control)

func _create_supporting_controllers() -> void:
    # Create scene tab controller
    var scene_tab_script = load(SCENE_TAB_CONTROLLER_PATH)
    if scene_tab_script:
        _scene_tab_controller = scene_tab_script.new()
    else:
        push_error("Failed to load SceneTabController from: " + SCENE_TAB_CONTROLLER_PATH)

    # Create options tab controller
    var options_tab_script = load(OPTIONS_TAB_CONTROLLER_PATH)
    if options_tab_script:
        _options_tab_controller = options_tab_script.new()
    else:
        push_error("Failed to load OptionsTabController from: " + OPTIONS_TAB_CONTROLLER_PATH)

    # Create tree selection controller
    var tree_selection_script = load(TREE_SELECTION_CONTROLLER_PATH)
    if tree_selection_script:
        _tree_selection_controller = tree_selection_script.new()
    else:
        push_error("Failed to load TreeSelectionController from: " + TREE_SELECTION_CONTROLLER_PATH)

func _initialize_progress_controller(parent_control: Control) -> void:
    var controller_script = load(PROGRESS_DIALOG_CONTROLLER_PATH)
    if controller_script:
        _progress_dialog_controller = controller_script.new()
        if _progress_dialog_controller:
            _progress_dialog_controller.initialize(parent_control)
        else:
            push_error("Failed to instantiate ProgressDialogController")
    else:
        push_error("Failed to load ProgressDialogController from: " + PROGRESS_DIALOG_CONTROLLER_PATH)

func _initialize_view(parent_control: Control) -> void:
    var view_script = load(EXPORT_DIALOG_VIEW_PATH)
    if view_script:
        # Pass this controller and all needed sub-controllers to the view
        _view = view_script.new(self, _scene_tab_controller, _options_tab_controller, _tree_selection_controller)
        if _view:
            _view.initialize(parent_control)
        else:
            push_error("Failed to instantiate ExportDialogView")
    else:
        push_error("Failed to load ExportDialogView from: " + EXPORT_DIALOG_VIEW_PATH)

func show_dialog(root_node: Node) -> void:
    if not root_node:
        push_error("Root node is null in ExportDialogController.show_dialog")
        return

    if _model:
        _model.set_current_root(root_node)

    if _view:
        _view.show_dialog(root_node)

func set_tree_selection_controller(controller) -> void:
    _tree_selection_controller = controller

func get_tree_selection_controller():
    return _tree_selection_controller

func set_tab_controllers(scene_tab_controller, options_tab_controller) -> void:
    _scene_tab_controller = scene_tab_controller
    _options_tab_controller = options_tab_controller

func _on_export_confirmed() -> void:
    if not _validate_export_prerequisites():
        return

    _progress_dialog_controller.show_progress()
    _prepare_and_execute_export()

func _validate_export_prerequisites() -> bool:
    if not _progress_dialog_controller:
        push_error("Progress dialog controller is null during export")
        return false

    if not _options_tab_controller:
        push_error("Options tab controller is null during export")
        return false

    if not _tree_selection_controller:
        push_error("Tree selection controller is null during export")
        return false

    return true

func _prepare_and_execute_export() -> void:
    # Get options from the options tab
    var export_options = _options_tab_controller.get_export_options()
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
    if action_name == "copy_to_clipboard":
        _handle_copy_to_clipboard()

func _handle_copy_to_clipboard() -> void:
    if not _validate_export_prerequisites():
        return

    # Get options from the options tab
    var export_options = _options_tab_controller.get_export_options()
    _model.set_export_options(export_options)

    # Find the highest selected node in the hierarchy
    var selected_node = _tree_selection_controller.find_highest_selected_node()
    _model.set_selected_node(selected_node)

    if selected_node:
        _process_clipboard_export(selected_node)
    else:
        _view.show_error_dialog("No Node Selected", "Please select a node in the scene tree first.")

func _process_clipboard_export(selected_node: Node) -> void:
    # Show a processing notification
    var notification = _view.show_clipboard_notification("Processing scene export for clipboard...")

    # Prepare export data and process
    var export_data = _model.prepare_export_data()
    var output_text = _model.process_export_to_clipboard(export_data)

    # Copy to clipboard
    DisplayServer.clipboard_set(output_text)

    # Update notification
    notification.dialog_text = "Scene export copied to clipboard!"

func _on_canceled() -> void:
    if _model:
        _model.set_current_root(null)
        _model.set_selected_node(null)

func _clean_up_notification(notification) -> void:
    if notification and is_instance_valid(notification):
        notification.queue_free()

# Progress dialog forwarding methods
func update_progress(progress: int, message: String) -> void:
    if _progress_dialog_controller:
        _progress_dialog_controller.update_progress(progress, message)
    else:
        push_error("Progress dialog controller is null during update_progress")

func hide_progress_dialog() -> void:
    if _progress_dialog_controller:
        _progress_dialog_controller.hide_progress()
    else:
        push_error("Progress dialog controller is null during hide_progress_dialog")

func finalize_export() -> void:
    if _progress_dialog_controller:
        _progress_dialog_controller.update_progress(100, "Export completed!")
    else:
        push_error("Progress dialog controller is null during finalize_export")
