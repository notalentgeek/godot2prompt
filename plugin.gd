@tool
extends EditorPlugin

"""
Main plugin entry point for Godot2Prompt.
Registers the plugin with Godot and handles initialization and cleanup.
"""

# Constants
const SCENE_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/scene_manager.gd"
const EXPORT_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/export_manager.gd"
const ERROR_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/error_manager.gd"
const SCREENSHOT_MANAGER_PATH: String = "res://addons/godot2prompt/core/managers/screenshot_manager.gd"
const EXPORT_DIALOG_CONTROLLER_PATH: String = "res://addons/godot2prompt/ui/controllers/export_dialog_controller.gd"
const SCENE_FILE_PATH: String = "res://scene_hierarchy.txt"
const SCREENSHOT_FILE_PATH: String = "res://scene_screenshot.png"

# Managers
var _scene_manager = null
var _export_manager = null
var _screenshot_manager = null
var _error_manager = null

# UI
var _export_dialog_controller = null

# Menu item names for removal
const SCENE_EXPORT_MENU_ITEM: String = "Scene to Prompt"
const QUICK_EXPORT_MENU_ITEM: String = "Quick Scene Export with Screenshot"

func _enter_tree():
	"""
	Initialize the plugin when it is enabled in the project settings.
	"""
	print("Godot2Prompt: Plugin enabled")

	# Initialize managers
	_init_managers()

	# Initialize UI components
	_init_ui_components()

	# Add editor buttons
	_add_editor_buttons()

func _exit_tree():
	"""
	Clean up the plugin when it is disabled in the project settings.
	"""
	print("Godot2Prompt: Plugin disabled")

	# Remove editor buttons
	_remove_editor_buttons()

	# Clean up UI components
	_cleanup_ui_components()

	# Clean up managers
	_cleanup_managers()

func _init_managers():
	"""
	Initialize the various managers used by the plugin.
	"""
	var SceneManager = load(SCENE_MANAGER_PATH)
	var ExportManager = load(EXPORT_MANAGER_PATH)
	var ErrorManager = load(ERROR_MANAGER_PATH)
	var ScreenshotManager = load(SCREENSHOT_MANAGER_PATH)

	if SceneManager:
		_scene_manager = SceneManager.new()

	if ExportManager:
		_export_manager = ExportManager.new()

	if ErrorManager:
		_error_manager = ErrorManager.new()
		_error_manager.start_monitoring()

	if ScreenshotManager:
		_screenshot_manager = ScreenshotManager.new()

func _init_ui_components():
	"""
	Initialize UI components used by the plugin.
	"""
	var ExportDialogController = load(EXPORT_DIALOG_CONTROLLER_PATH)

	if ExportDialogController:
		_export_dialog_controller = ExportDialogController.new()
		_export_dialog_controller.initialize(get_editor_interface().get_base_control())
		_export_dialog_controller.connect("export_hierarchy", Callable(self, "_on_export_hierarchy"))

func _add_editor_buttons():
	"""
	Add buttons to the editor toolbar for quick access to plugin features.
	"""
	# Scene to Prompt menu option
	add_tool_menu_item(SCENE_EXPORT_MENU_ITEM, Callable(self, "_on_scene_export_pressed"))

	# Quick export menu option
	add_tool_menu_item(QUICK_EXPORT_MENU_ITEM, Callable(self, "_on_quick_export_pressed"))

func _remove_editor_buttons():
	"""
	Remove buttons from the editor toolbar.
	"""
	remove_tool_menu_item(SCENE_EXPORT_MENU_ITEM)
	remove_tool_menu_item(QUICK_EXPORT_MENU_ITEM)

func _cleanup_ui_components():
	"""
	Clean up UI components when the plugin is disabled.
	"""
	# Check if the controller can be freed with queue_free()
	if _export_dialog_controller:
		if _export_dialog_controller is Node and is_instance_valid(_export_dialog_controller):
			_export_dialog_controller.queue_free()
		# Otherwise just set to null - GDScript will handle reference counting
		_export_dialog_controller = null

func _cleanup_managers():
	"""
	Clean up managers when the plugin is disabled.
	"""
	# Error manager cleanup
	if _error_manager:
		if _error_manager.has_method("stop_monitoring"):
			_error_manager.stop_monitoring()
		_error_manager = null

	# Other managers - GDScript will handle reference counting
	_scene_manager = null
	_export_manager = null
	_screenshot_manager = null

func _on_scene_export_pressed():
	"""
	Handle the Scene to Prompt toolbar button press.
	"""
	if _export_dialog_controller:
		var root = get_editor_interface().get_edited_scene_root()
		if root:
			_export_dialog_controller.show_dialog(root)
		else:
			_show_error_dialog("No Scene Open", "Please open a scene before exporting.")

func _on_quick_export_pressed():
	"""
	Handle the Quick Export toolbar button press.
	Exports the current scene with default settings and a screenshot.
	"""
	var root = get_editor_interface().get_edited_scene_root()
	if root:
		# Set default export options
		var include_scripts = true
		var include_properties = true
		var include_signals = true
		var include_errors = true
		var include_project_settings = false
		var enabled_setting_categories = []
		var include_screenshot = true

		# Perform export
		_on_export_hierarchy(root, include_scripts, include_properties, include_signals,
						 include_errors, include_project_settings, enabled_setting_categories,
						 include_screenshot)
	else:
		_show_error_dialog("No Scene Open", "Please open a scene before exporting.")

func _on_export_hierarchy(selected_node, include_scripts, include_properties, include_signals,
						 include_errors, include_project_settings, enabled_setting_categories,
						 include_screenshot):
	"""
	Handle the export hierarchy request from the export dialog.
	"""
	include_screenshot = true
	print("Godot2Prompt: Force-enabling screenshot for testing")
	if not selected_node or not _scene_manager or not _export_manager:
		print("Godot2Prompt: Export hierarchy failed - Missing required components")
		return

	# Show progress dialog
	_export_dialog_controller.show_progress()
	_export_dialog_controller.update_progress(10, "Capturing scene data...")

	# Get error log if needed
	var error_log = []
	if include_errors and _error_manager:
		error_log = _error_manager.get_errors()

	# Take screenshot if needed
	var screenshot_path = ""
	if include_screenshot and _screenshot_manager:
		print("Godot2Prompt: Attempting to capture screenshot...")
		_export_dialog_controller.update_progress(20, "Capturing screenshot...")
		screenshot_path = _screenshot_manager.capture_editor_screenshot(get_editor_interface())
		print("Godot2Prompt: Screenshot capture result: " + ("Success" if screenshot_path else "Failed"))
		if screenshot_path:
			print("Godot2Prompt: Screenshot saved to: " + screenshot_path)
	else:
		print("Godot2Prompt: Skipping screenshot - " +
			("Screenshot not requested" if not include_screenshot else "Screenshot manager not available"))

	# Process scene data
	_export_dialog_controller.update_progress(40, "Processing scene hierarchy...")

	# Debug the scene data processing
	print("Godot2Prompt: Processing scene with screenshot_path: " + screenshot_path)

	# Note: process_scene doesn't have include_scripts parameter!
	# We need to align our parameters with what process_scene expects
	var scene_data = _scene_manager.process_scene(
		selected_node,
		include_properties,
		include_signals,
		error_log,
		include_project_settings,
		enabled_setting_categories,
		screenshot_path
	)

	if not scene_data:
		_export_dialog_controller.hide_progress()
		_show_error_dialog("Export Failed", "Failed to process scene data.")
		print("Godot2Prompt: Scene processing failed - null scene_data returned")
		return

	# Export to file
	_export_dialog_controller.update_progress(80, "Writing output file...")
	var success = _export_manager.export_to_file(scene_data, SCENE_FILE_PATH)
	print("Godot2Prompt: Export to file result: " + ("Success" if success else "Failed"))

	_export_dialog_controller.update_progress(100, "Export completed!")

	# Show completion message
	if success:
		var message = "Scene hierarchy exported to " + SCENE_FILE_PATH
		if include_screenshot and not screenshot_path.is_empty():
			message += "\nScreenshot saved to " + screenshot_path
			# Verify if the file actually exists
			var file_exists = FileAccess.file_exists(screenshot_path)
			print("Godot2Prompt: Screenshot file exists check: " + str(file_exists))
		_show_info_dialog("Export Complete", message)
	else:
		_show_error_dialog("Export Failed", "Failed to write output file.")

	# Hide progress dialog
	_export_dialog_controller.hide_progress()

func _show_error_dialog(title: String, message: String):
	"""
	Show an error dialog with the specified title and message.

	Args:
		title: The dialog title
		message: The error message
	"""
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()

	# Auto-free dialog when confirmed
	dialog.connect("confirmed", Callable(dialog, "queue_free"))

func _show_info_dialog(title: String, message: String):
	"""
	Show an information dialog with the specified title and message.

	Args:
		title: The dialog title
		message: The information message
	"""
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()

	# Auto-free dialog when confirmed
	dialog.connect("confirmed", Callable(dialog, "queue_free"))
