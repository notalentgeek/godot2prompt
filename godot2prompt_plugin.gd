@tool
extends EditorPlugin

# Constants - Menu Items
const EXPORT_MENU_ITEM: String = "Scene to Prompt"
const QUICK_EXPORT_MENU_ITEM: String = "Quick Scene Export with Screenshot"

# Constants - Paths
const ERROR_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/error_manager.gd"
const EXPORT_DIALOG_PATH: String = "res://addons/godot2prompt/ui/export_dialog.gd"
const EXPORT_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/export_manager.gd"
const FILE_HANDLER_PATH: String = "res://addons/godot2prompt/core/io/file_handler.gd"
const SCENE_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/scene_manager.gd"
const SCREENSHOT_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/screenshot_manager.gd"

# Constants - File Paths
const DEFAULT_EXPORT_PATH: String = "res://scene_hierarchy.txt"

# Core components
var _editor_interface: EditorInterface
var _error_manager
var _export_manager
var _file_handler
var _scene_manager
var _screenshot_manager
var _ui_manager

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
	_error_manager = load(ERROR_MANAGER_PATH).new()
	_export_manager = load(EXPORT_MANAGER_PATH).new()
	_file_handler = load(FILE_HANDLER_PATH).new()
	_scene_manager = load(SCENE_MANAGER_PATH).new()
	_screenshot_manager = load(SCREENSHOT_MANAGER_PATH).new()
	_ui_manager = load(EXPORT_DIALOG_PATH).new()

	# Initialize the export manager with required dependencies
	_export_manager.initialize(
		_editor_interface,
		_error_manager,
		_file_handler,
		_scene_manager,
		_screenshot_manager,
		_ui_manager
	)

func _initialize_timers() -> void:
	# Export timer for standard delay
	_export_timer = Timer.new()
	_export_timer.one_shot = true
	_export_timer.wait_time = 0.5
	_export_timer.connect("timeout", Callable(self, "_on_export_timer_timeout"))
	add_child(_export_timer)

	# Completion timer for longer display of completion message
	_completion_timer = Timer.new()
	_completion_timer.one_shot = true
	_completion_timer.wait_time = 2.0
	_completion_timer.connect("timeout", Callable(self, "_on_completion_timer_timeout"))
	add_child(_completion_timer)

	# Pass timers to export manager
	_export_manager.set_timers(_export_timer, _completion_timer)

func _setup_error_monitoring() -> void:
	if not _error_manager.log_monitor or not _error_manager.log_monitor.log_check_timer:
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
	if _completion_timer:
		_completion_timer.queue_free()
		_completion_timer = null

	if _export_timer:
		_export_timer.queue_free()
		_export_timer = null

func _clean_up_references() -> void:
	# No need to call queue_free on RefCounted objects
	_error_manager = null
	_export_manager = null
	_file_handler = null
	_scene_manager = null
	_screenshot_manager = null
	_ui_manager = null

# Menu action methods
func export_scene_hierarchy() -> void:
	var root = _editor_interface.get_edited_scene_root()
	if not root:
		_export_manager.show_error_dialog("No Scene Open",
			"Please open a scene before using Scene to Prompt.\n\nThis tool exports the hierarchy of an open scene.")
		return

	_export_manager.show_export_dialog(root)

func quick_export_with_screenshot() -> void:
	var root = _editor_interface.get_edited_scene_root()
	if not root:
		_export_manager.show_error_dialog("No Scene Open", "Please open a scene before using Quick Export.")
		return

	_export_manager.execute_quick_export(root)

# Timer signal handlers
func _on_export_timer_timeout() -> void:
	if _ui_manager:
		_ui_manager.hide_progress_dialog()

func _on_completion_timer_timeout() -> void:
	if _ui_manager:
		_ui_manager.hide_progress_dialog()
