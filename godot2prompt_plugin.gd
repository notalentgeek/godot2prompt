@tool
extends EditorPlugin

# Constants - Menu Items
const EXPORT_MENU_ITEM: String = "Scene to Prompt"
const QUICK_EXPORT_MENU_ITEM: String = "Quick Scene Export with Screenshot"

# Constants - Paths
const ERROR_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/error_manager.gd"
const EXPORT_DIALOG_CONTROLLER_PATH: String = "res://addons/godot2prompt/ui/controllers/export_dialog_controller.gd"
const EXPORT_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/export_manager.gd"
const FILE_SYSTEM_PATH: String = "res://addons/godot2prompt/core/io/file_system.gd"
const SCENE_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/scene_manager.gd"
const SCREENSHOT_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/screenshot_manager.gd"

# Preloaded Scripts
const ErrorManagerScript = preload(ERROR_MANAGER_PATH)
const ExportDialogControllerScript = preload(EXPORT_DIALOG_CONTROLLER_PATH)
const ExportManagerScript = preload(EXPORT_MANAGER_PATH)
const FileSystemScript = preload(FILE_SYSTEM_PATH)
const SceneManagerScript = preload(SCENE_MANAGER_PATH)
const ScreenshotManagerScript = preload(SCREENSHOT_MANAGER_PATH)

# Constants - File Paths
const DEFAULT_EXPORT_PATH: String = "res://scene_hierarchy.txt"

# Core components
var _editor_interface: EditorInterface
var _error_manager
var _export_dialog_controller
var _export_manager
var _file_system
var _scene_manager
var _screenshot_manager

# Timers
var _completion_timer: Timer
var _export_timer: Timer

func _enter_tree() -> void:
	_editor_interface = get_editor_interface()

	_initialize_managers()
	_initialize_timers()
	_setup_error_monitoring()
	_setup_menu_items()

func _exit_tree() -> void:
	_clean_up_error_monitoring()
	_clean_up_menu_items()
	_clean_up_timers()
	_clean_up_references()

# Initialization methods
func _initialize_managers() -> void:
	# Create instances using preloaded scripts
	_error_manager = ErrorManagerScript.new()
	_export_manager = ExportManagerScript.new()
	_file_system = FileSystemScript.new()
	_scene_manager = SceneManagerScript.new()
	_screenshot_manager = ScreenshotManagerScript.new()
	_export_dialog_controller = ExportDialogControllerScript.new()

	# Initialize the export dialog controller
	if _export_dialog_controller:
		_export_dialog_controller.initialize(_editor_interface.get_base_control())
	else:
		push_error("Failed to create export dialog controller")
		return

	# Initialize the export manager with required dependencies
	if _export_manager:
		_export_manager.initialize(
			_editor_interface,
			_error_manager,
			_file_system,
			_scene_manager,
			_screenshot_manager,
			_export_dialog_controller
		)
	else:
		push_error("Failed to create export manager")
		return

	# Connect export dialog controller signals to export manager
	_connect_controller_signals()

func _connect_controller_signals() -> void:
	if not _export_dialog_controller or not _export_manager:
		push_error("Cannot connect signals: controller or manager is null")
		return

	if not _export_dialog_controller.is_connected("export_hierarchy", Callable(_export_manager, "_on_export_hierarchy")):
		_export_dialog_controller.connect("export_hierarchy", Callable(_export_manager, "_on_export_hierarchy"))

	if not _export_dialog_controller.is_connected("export_progress", Callable(_export_manager, "_on_export_progress")):
		_export_dialog_controller.connect("export_progress", Callable(_export_manager, "_on_export_progress"))

func _initialize_timers() -> void:
	_create_export_timer()
	_create_completion_timer()

	# Pass timers to export manager
	if _export_manager:
		_export_manager.set_timers(_export_timer, _completion_timer)

func _create_export_timer() -> void:
	# Export timer for standard delay
	_export_timer = Timer.new()
	_export_timer.one_shot = true
	_export_timer.wait_time = 0.5
	_export_timer.connect("timeout", Callable(self, "_on_export_timer_timeout"))
	add_child(_export_timer)

func _create_completion_timer() -> void:
	# Completion timer for longer display of completion message
	_completion_timer = Timer.new()
	_completion_timer.one_shot = true
	_completion_timer.wait_time = 2.0
	_completion_timer.connect("timeout", Callable(self, "_on_completion_timer_timeout"))
	add_child(_completion_timer)

func _setup_error_monitoring() -> void:
	if not _error_manager or not _error_manager.log_monitor or not _error_manager.log_monitor.log_check_timer:
		push_error("Error monitoring could not be set up: missing components")
		return

	if not _error_manager.log_monitor.log_check_timer.is_inside_tree():
		add_child(_error_manager.log_monitor.log_check_timer)
		_error_manager.log_monitor.log_check_timer.start()
		print("Godot2Prompt: Error monitoring started")

func _setup_menu_items() -> void:
	add_tool_menu_item(EXPORT_MENU_ITEM, Callable(self, "export_scene_hierarchy"))
	add_tool_menu_item(QUICK_EXPORT_MENU_ITEM, Callable(self, "quick_export_with_screenshot"))

# Cleanup methods
func _clean_up_error_monitoring() -> void:
	if _error_manager:
		_error_manager.stop_monitoring()

func _clean_up_menu_items() -> void:
	remove_tool_menu_item(EXPORT_MENU_ITEM)
	remove_tool_menu_item(QUICK_EXPORT_MENU_ITEM)

func _clean_up_timers() -> void:
	if _completion_timer and is_instance_valid(_completion_timer):
		_completion_timer.queue_free()
		_completion_timer = null

	if _export_timer and is_instance_valid(_export_timer):
		_export_timer.queue_free()
		_export_timer = null

func _clean_up_references() -> void:
	# No need to call queue_free on RefCounted objects
	_error_manager = null
	_export_manager = null
	_file_system = null
	_scene_manager = null
	_screenshot_manager = null
	_export_dialog_controller = null

# Menu action methods
func export_scene_hierarchy() -> void:
	var root = _editor_interface.get_edited_scene_root()
	if not root:
		if _export_manager:
			_export_manager.show_error_dialog("No Scene Open",
				"Please open a scene before using Scene to Prompt.\n\nThis tool exports the hierarchy of an open scene.")
		return

	if _export_manager:
		_export_manager.show_export_dialog(root)
	else:
		push_error("Cannot export scene: export manager is null")

func quick_export_with_screenshot() -> void:
	var root = _editor_interface.get_edited_scene_root()
	if not root:
		if _export_manager:
			_export_manager.show_error_dialog("No Scene Open", "Please open a scene before using Quick Export.")
		return

	if _export_manager:
		_export_manager.execute_quick_export(root)
	else:
		push_error("Cannot quick export scene: export manager is null")

# Timer signal handlers
func _on_export_timer_timeout() -> void:
	if _export_dialog_controller:
		_export_dialog_controller.hide_progress_dialog()

func _on_completion_timer_timeout() -> void:
	if _export_dialog_controller:
		_export_dialog_controller.hide_progress_dialog()
