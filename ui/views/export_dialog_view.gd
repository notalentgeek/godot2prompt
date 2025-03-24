@tool
extends RefCounted
class_name ExportDialogView

"""
ExportDialogView creates and manages the UI for the export dialog.
It handles the visual representation of the export options and process.
"""

# Constants
const CLIPBOARD_BUTTON_TEXT: String = "Copy to Clipboard"
const DIALOG_MIN_SIZE: Vector2 = Vector2(500, 500)
const DIALOG_TITLE: String = "Scene to Prompt"
const EXPORT_BUTTON_TEXT: String = "Export"
const OPTIONS_TAB_TITLE: String = "Options"
const SCENE_TAB_TITLE: String = "Scene"

# Tab controllers
var _options_tab_controller = null
var _scene_tab_controller = null

# UI components
var _controller = null
var _dialog: ConfirmationDialog = null
var _main_tabs: TabContainer = null
var _options_tab: Control = null
var _parent_control: Control = null
var _scene_tab: Control = null

func _init(controller):
	"""
	Initialize the view with a reference to its controller.

	Args:
		controller: The controller that manages this view
	"""
	_controller = controller

func initialize(parent_control: Control) -> void:
	"""
	Initialize the view with the parent control.

	Args:
		parent_control: The parent control to attach UI elements to
	"""
	_parent_control = parent_control

	# Create dialog if it doesn't exist
	if _dialog == null:
		_create_dialog()
		_create_tab_container()
		_initialize_tabs()
		_add_custom_buttons()
		_connect_signals()

func _create_dialog() -> void:
	"""
	Create the confirmation dialog for the export options.
	"""
	# Create a custom confirmation dialog
	_dialog = ConfirmationDialog.new()
	_parent_control.add_child(_dialog)

	# Configure dialog properties
	_dialog.title = DIALOG_TITLE
	_dialog.min_size = DIALOG_MIN_SIZE
	_dialog.ok_button_text = EXPORT_BUTTON_TEXT

func _create_tab_container() -> void:
	"""
	Create the tab container for organizing different option sections.
	"""
	_main_tabs = TabContainer.new()
	_main_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialog.add_child(_main_tabs)

func _initialize_tabs() -> void:
	"""
	Initialize the tabs for scene and options.
	"""
	# Load controller classes
	var SceneTabController = load("res://addons/godot2prompt/ui/controllers/scene_tab_controller.gd")
	var TreeSelectionController = load("res://addons/godot2prompt/ui/controllers/tree_selection_controller.gd")
	var OptionsTabController = load("res://addons/godot2prompt/ui/controllers/options_tab_controller.gd")

	# Initialize scene tab
	_scene_tab_controller = SceneTabController.new()
	_scene_tab = _scene_tab_controller.create_scene_tab()
	_main_tabs.add_child(_scene_tab)
	_main_tabs.set_tab_title(0, SCENE_TAB_TITLE)

	# Initialize tree selection
	var tree_selection_controller = TreeSelectionController.new()
	tree_selection_controller.initialize(_scene_tab_controller.get_tree())
	_controller.set_tree_selection_controller(tree_selection_controller)

	# Initialize options tab
	_options_tab_controller = OptionsTabController.new()
	_options_tab = _options_tab_controller.create_options_tab()
	_main_tabs.add_child(_options_tab)
	_main_tabs.set_tab_title(1, OPTIONS_TAB_TITLE)

	# Pass controllers to main controller
	_controller.set_tab_controllers(_scene_tab_controller, _options_tab_controller)

func _add_custom_buttons() -> void:
	"""
	Add custom buttons to the dialog.
	"""
	_dialog.add_button(CLIPBOARD_BUTTON_TEXT, true, "copy_to_clipboard")

func _connect_signals() -> void:
	"""
	Connect dialog signals to controller methods.
	"""
	_dialog.connect("confirmed", Callable(_controller, "_on_export_confirmed"))
	_dialog.connect("canceled", Callable(_controller, "_on_canceled"))
	_dialog.connect("custom_action", Callable(_controller, "_on_custom_action"))

func show_dialog(root_node: Node) -> void:
	"""
	Show the export dialog with the given root node.

	Args:
		root_node: The root node to display in the dialog
	"""
	if not _dialog:
		return

	# Initialize the tree with the root node
	_scene_tab_controller.clear_tree()
	_controller.get_tree_selection_controller().initialize_tree_with_root(root_node)

	# Populate settings categories in options tab
	_options_tab_controller.populate_settings_categories()

	# Show the dialog
	_dialog.popup_centered()

func show_clipboard_notification(message: String) -> AcceptDialog:
	"""
	Show a clipboard notification dialog.

	Args:
		message: The message to display

	Returns:
		The created notification dialog
	"""
	var notification = AcceptDialog.new()
	notification.title = "Copying to Clipboard"
	notification.dialog_text = message
	notification.exclusive = false

	_parent_control.add_child(notification)
	notification.popup_centered()

	notification.connect("confirmed", Callable(_controller, "_clean_up_notification").bind(notification))

	return notification

func show_clipboard_size_warning(line_count: int, max_lines: int) -> void:
	"""
	Show a warning dialog when content is too large for clipboard.

	Args:
		line_count: The number of lines in the export
		max_lines: The maximum number of lines allowed for clipboard
	"""
	var warning_dialog = AcceptDialog.new()
	warning_dialog.title = "Content Too Large"
	warning_dialog.dialog_text = "The selected content contains " + str(line_count) + " lines, which exceeds the maximum of " + str(max_lines) + " lines for clipboard operations.\n\nPlease use the 'Export' button instead to save the content to a file."
	warning_dialog.exclusive = true
	warning_dialog.min_size = Vector2(400, 150)

	_parent_control.add_child(warning_dialog)
	warning_dialog.popup_centered()

	warning_dialog.connect("confirmed", Callable(_controller, "_clean_up_notification").bind(warning_dialog))

func show_error_dialog(title: String, message: String) -> void:
	"""
	Show an error dialog.

	Args:
		title: The dialog title
		message: The error message to display
	"""
	var error_dialog = AcceptDialog.new()
	error_dialog.title = title
	error_dialog.dialog_text = message
	error_dialog.exclusive = false

	_parent_control.add_child(error_dialog)
	error_dialog.popup_centered()

	error_dialog.connect("confirmed", Callable(_controller, "_clean_up_notification").bind(error_dialog))
