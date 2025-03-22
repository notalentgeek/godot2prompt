@tool
extends RefCounted
class_name ExportDialogView

# Constants
const CLIPBOARD_BUTTON_TEXT: String = "Copy to Clipboard"
const DIALOG_MIN_SIZE: Vector2 = Vector2(500, 500)
const DIALOG_TITLE: String = "Scene to Prompt"
const EXPORT_BUTTON_TEXT: String = "Export"
const OPTIONS_TAB_TITLE: String = "Options"
const SCENE_TAB_TITLE: String = "Scene"

# Tab controllers - passed in from main controller
var _options_tab_controller
var _scene_tab_controller
var _tree_selection_controller

# UI components
var _controller = null
var _dialog: ConfirmationDialog = null
var _main_tabs: TabContainer = null
var _options_tab: Control = null
var _parent_control: Control = null
var _scene_tab: Control = null

# Modified constructor to accept all necessary controllers
func _init(controller, scene_tab_controller = null, options_tab_controller = null, tree_selection_controller = null):
    _controller = controller
    _scene_tab_controller = scene_tab_controller
    _options_tab_controller = options_tab_controller
    _tree_selection_controller = tree_selection_controller

func initialize(parent_control: Control) -> void:
    if not parent_control:
        push_error("Parent control is null in ExportDialogView.initialize")
        return

    _parent_control = parent_control

    # Create dialog if it doesn't exist
    if _dialog == null:
        _create_dialog()
        _create_tab_container()
        _setup_tabs()
        _add_custom_buttons()
        _connect_signals()

func _create_dialog() -> void:
    # Create a custom confirmation dialog
    _dialog = ConfirmationDialog.new()
    _parent_control.add_child(_dialog)

    # Configure dialog properties
    _dialog.title = DIALOG_TITLE
    _dialog.min_size = DIALOG_MIN_SIZE
    _dialog.ok_button_text = EXPORT_BUTTON_TEXT

func _create_tab_container() -> void:
    _main_tabs = TabContainer.new()
    _main_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _main_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _dialog.add_child(_main_tabs)

func _setup_tabs() -> void:
    # Setup scene tab if controller was provided
    if _scene_tab_controller:
        _setup_scene_tab()
    else:
        push_error("Scene tab controller is null during tab setup")

    # Setup options tab if controller was provided
    if _options_tab_controller:
        _setup_options_tab()
    else:
        push_error("Options tab controller is null during tab setup")

func _setup_scene_tab() -> void:
    # Create the scene tab using the provided controller
    _scene_tab = _scene_tab_controller.create_scene_tab()
    _main_tabs.add_child(_scene_tab)
    _main_tabs.set_tab_title(0, SCENE_TAB_TITLE)

    # Setup tree selection if controller was provided
    if _tree_selection_controller:
        _tree_selection_controller.initialize(_scene_tab_controller.get_tree())
    else:
        push_error("Tree selection controller is null during scene tab setup")

func _setup_options_tab() -> void:
    # Create the options tab using the provided controller
    _options_tab = _options_tab_controller.create_options_tab()
    _main_tabs.add_child(_options_tab)
    _main_tabs.set_tab_title(1, OPTIONS_TAB_TITLE)

func _add_custom_buttons() -> void:
    _dialog.add_button(CLIPBOARD_BUTTON_TEXT, true, "copy_to_clipboard")

func _connect_signals() -> void:
    _dialog.connect("confirmed", Callable(_controller, "_on_export_confirmed"))
    _dialog.connect("canceled", Callable(_controller, "_on_canceled"))
    _dialog.connect("custom_action", Callable(_controller, "_on_custom_action"))

func show_dialog(root_node: Node) -> void:
    if not _dialog:
        push_error("Dialog is null in show_dialog")
        return

    if not _scene_tab_controller:
        push_error("Scene tab controller is null in show_dialog")
        return

    if not _tree_selection_controller:
        push_error("Tree selection controller is null in show_dialog")
        return

    # Initialize the tree with the root node
    _scene_tab_controller.clear_tree()
    _tree_selection_controller.initialize_tree_with_root(root_node)

    # Populate settings categories in options tab
    if _options_tab_controller:
        _options_tab_controller.populate_settings_categories()
    else:
        push_error("Options tab controller is null when populating settings")

    # Show the dialog
    _dialog.popup_centered()

func show_clipboard_notification(message: String) -> AcceptDialog:
    if not _parent_control:
        push_error("Parent control is null when showing clipboard notification")
        return null

    var notification = AcceptDialog.new()
    notification.title = "Copying to Clipboard"
    notification.dialog_text = message
    notification.exclusive = false

    _parent_control.add_child(notification)
    notification.popup_centered()

    notification.connect("confirmed", Callable(_controller, "_clean_up_notification").bind(notification))

    return notification

func show_error_dialog(title: String, message: String) -> void:
    if not _parent_control:
        push_error("Parent control is null when showing error dialog")
        return

    var error_dialog = AcceptDialog.new()
    error_dialog.title = title
    error_dialog.dialog_text = message
    error_dialog.exclusive = false

    _parent_control.add_child(error_dialog)
    error_dialog.popup_centered()

    error_dialog.connect("confirmed", Callable(_controller, "_clean_up_notification").bind(error_dialog))
