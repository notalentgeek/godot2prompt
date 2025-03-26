@tool
extends EditorPlugin

"""
Main plugin entry point for Godot2Prompt.
Registers the plugin with Godot and handles initialization and cleanup.
"""

# Constants
const SCRIPT_LOADER_PATH: String = "res://addons/godot2prompt/utils/script_loader.gd"
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

func _enter_tree() -> void:
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

func _exit_tree() -> void:
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

func _init_managers() -> void:
	"""
	Initialize the various managers used by the plugin using robust script loading.
	"""
	# First ensure the script loader is available
	var script_loader = load(SCRIPT_LOADER_PATH)

	# If script_loader is not available, use manual instantiation
	if script_loader == null:
		push_error("Godot2Prompt: Failed to load ScriptLoader, using direct instantiation")
		_init_managers_directly()
		return

	# Proper way to check for a class vs a script object
	if script_loader is GDScript:
		# Instantiate managers using the script loader class
		_scene_manager = _instantiate_script(SCENE_MANAGER_PATH)
		_export_manager = _instantiate_script(EXPORT_MANAGER_PATH)
		_error_manager = _instantiate_script(ERROR_MANAGER_PATH)
		_screenshot_manager = _instantiate_script(SCREENSHOT_MANAGER_PATH)

		# Start error monitoring if available
		if _error_manager and _error_manager.has_method("start_monitoring"):
			_error_manager.start_monitoring()
	else:
		push_error("Godot2Prompt: ScriptLoader is not a GDScript, using direct instantiation")
		_init_managers_directly()

func _instantiate_script(path: String) -> Object:
	"""
	Helper method to instantiate a script with error handling.

	Args:
		path: Path to the script to instantiate

	Returns:
		The instantiated object or null if instantiation failed
	"""
	var script = load(path)
	if script == null:
		push_error("Godot2Prompt: Failed to load script from: " + path)
		return null

	if not script is GDScript:
		push_error("Godot2Prompt: Loaded resource is not a GDScript: " + path)
		return null

	# Instead of calling new() directly on the script,
	# create a new RefCounted object and set the script on it
	var instance = RefCounted.new()
	instance.set_script(script)

	# Check if script was set successfully by checking if known method exists
	if not instance.has_method("_init"):
		push_error("Godot2Prompt: Failed to set script on instance: " + path)
		return null

	return instance

func _init_managers_directly() -> void:
	"""
	Alternative method to initialize managers directly when script loader fails.
	"""
	# Scene Manager
	var scene_manager_script = load(SCENE_MANAGER_PATH)
	if scene_manager_script is GDScript:
		_scene_manager = RefCounted.new()
		_scene_manager.set_script(scene_manager_script)

	# Export Manager
	var export_manager_script = load(EXPORT_MANAGER_PATH)
	if export_manager_script is GDScript:
		_export_manager = RefCounted.new()
		_export_manager.set_script(export_manager_script)

	# Error Manager
	var error_manager_script = load(ERROR_MANAGER_PATH)
	if error_manager_script is GDScript:
		_error_manager = RefCounted.new()
		_error_manager.set_script(error_manager_script)
		if _error_manager.has_method("start_monitoring"):
			_error_manager.start_monitoring()

	# Screenshot Manager
	var screenshot_manager_script = load(SCREENSHOT_MANAGER_PATH)
	if screenshot_manager_script is GDScript:
		_screenshot_manager = RefCounted.new()
		_screenshot_manager.set_script(screenshot_manager_script)

func _init_ui_components() -> void:
	"""
	Initialize UI components used by the plugin.
	"""
	var export_dialog_controller_script = load(EXPORT_DIALOG_CONTROLLER_PATH)

	if export_dialog_controller_script is GDScript:
		# Create a new instance and set the script
		_export_dialog_controller = RefCounted.new()
		_export_dialog_controller.set_script(export_dialog_controller_script)

		# Only initialize if we successfully set the script
		if _export_dialog_controller.has_method("initialize"):
			_export_dialog_controller.initialize(get_editor_interface().get_base_control())

		# Connect signals if both objects are valid
		if _export_dialog_controller.has_method("connect"):
			_export_dialog_controller.connect("export_hierarchy", Callable(self, "_on_export_hierarchy"))
		else:
			push_error("Godot2Prompt: Export dialog controller does not have connect method")

func _add_editor_buttons() -> void:
	"""
	Add buttons to the editor toolbar for quick access to plugin features.
	"""
	# Scene to Prompt menu option
	add_tool_menu_item(SCENE_EXPORT_MENU_ITEM, Callable(self, "_on_scene_export_pressed"))

	# Quick export menu option
	add_tool_menu_item(QUICK_EXPORT_MENU_ITEM, Callable(self, "_on_quick_export_pressed"))

func _remove_editor_buttons() -> void:
	"""
	Remove buttons from the editor toolbar.
	"""
	remove_tool_menu_item(SCENE_EXPORT_MENU_ITEM)
	remove_tool_menu_item(QUICK_EXPORT_MENU_ITEM)

func _cleanup_ui_components() -> void:
	"""
	Clean up UI components when the plugin is disabled.
	"""
	# Check if the controller can be freed with queue_free()
	if _export_dialog_controller:
		if _export_dialog_controller is Node and is_instance_valid(_export_dialog_controller):
			_export_dialog_controller.queue_free()
		# Otherwise just set to null - GDScript will handle reference counting
		_export_dialog_controller = null

func _cleanup_managers() -> void:
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

func _on_scene_export_pressed() -> void:
	"""
	Handle the Scene to Prompt toolbar button press.
	"""
	if _export_dialog_controller:
		var root = get_editor_interface().get_edited_scene_root()
		if root:
			if _export_dialog_controller.has_method("show_dialog"):
				_export_dialog_controller.show_dialog(root)
			else:
				push_error("Godot2Prompt: Export dialog controller does not have show_dialog method")
				_show_error_dialog("Export Failed", "Failed to show export dialog.")
		else:
			_show_error_dialog("No Scene Open", "Please open a scene before exporting.")
	else:
		push_error("Godot2Prompt: Export dialog controller is not initialized")
		_show_error_dialog("Export Failed", "Export dialog controller is not initialized.")

func _on_quick_export_pressed() -> void:
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
						 include_screenshot) -> void:
	"""
	Handle the export hierarchy request from the export dialog.

	Args:
		selected_node: The root node to export
		include_scripts: Whether to include scripts in the export
		include_properties: Whether to include properties in the export
		include_signals: Whether to include signals in the export
		include_errors: Whether to include errors in the export
		include_project_settings: Whether to include project settings in the export
		enabled_setting_categories: Which setting categories to include
		include_screenshot: Whether to include a screenshot in the export
	"""
	# Force screenshot to true for debugging/testing purposes
	include_screenshot = true
	print("Godot2Prompt: Force-enabling screenshot for testing")

	# Validate required components are available
	if not selected_node:
		push_error("Godot2Prompt: No node selected for export")
		_show_error_dialog("Export Failed", "No node selected for export.")
		return

	if not _scene_manager:
		push_error("Godot2Prompt: Scene manager not initialized")
		_show_error_dialog("Export Failed", "Scene manager not initialized.")
		return

	if not _export_manager:
		push_error("Godot2Prompt: Export manager not initialized")
		_show_error_dialog("Export Failed", "Export manager not initialized.")
		return

	# Check UI controller
	if not _export_dialog_controller:
		push_error("Godot2Prompt: Export dialog controller not initialized")
		_show_error_dialog("Export Failed", "Export dialog controller not initialized.")
		return

	# Make sure required methods exist
	if not _scene_manager.has_method("process_scene"):
		push_error("Godot2Prompt: Scene manager does not have process_scene method")
		_show_error_dialog("Export Failed", "Scene manager does not have required methods.")
		return

	if not _export_manager.has_method("export_to_file"):
		push_error("Godot2Prompt: Export manager does not have export_to_file method")
		_show_error_dialog("Export Failed", "Export manager does not have required methods.")
		return

	# Show progress dialog
	if _export_dialog_controller.has_method("show_progress"):
		_export_dialog_controller.show_progress()

	if _export_dialog_controller.has_method("update_progress"):
		_export_dialog_controller.update_progress(10, "Capturing scene data...")

	# Get error log if needed
	var error_log = []
	if include_errors and _error_manager and _error_manager.has_method("get_errors"):
		error_log = _error_manager.get_errors()

	# Take screenshot if needed
	var screenshot_path = ""
	if include_screenshot and _screenshot_manager:
		print("Godot2Prompt: Attempting to capture screenshot...")
		if _export_dialog_controller.has_method("update_progress"):
			_export_dialog_controller.update_progress(20, "Capturing screenshot...")

		if _screenshot_manager.has_method("capture_editor_screenshot"):
			screenshot_path = _screenshot_manager.capture_editor_screenshot(get_editor_interface())
			print("Godot2Prompt: Screenshot capture result: " + ("Success" if screenshot_path else "Failed"))
			if screenshot_path:
				print("Godot2Prompt: Screenshot saved to: " + screenshot_path)
		else:
			push_error("Godot2Prompt: Screenshot manager does not have capture_editor_screenshot method")
	else:
		print("Godot2Prompt: Skipping screenshot - " +
			("Screenshot not requested" if not include_screenshot else "Screenshot manager not available"))

	# Process scene data
	if _export_dialog_controller.has_method("update_progress"):
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
		if _export_dialog_controller.has_method("hide_progress"):
			_export_dialog_controller.hide_progress()
		_show_error_dialog("Export Failed", "Failed to process scene data.")
		print("Godot2Prompt: Scene processing failed - null scene_data returned")
		return

	# Export to file
	if _export_dialog_controller.has_method("update_progress"):
		_export_dialog_controller.update_progress(80, "Writing output file...")
	var success = _export_manager.export_to_file(scene_data, SCENE_FILE_PATH)
	print("Godot2Prompt: Export to file result: " + ("Success" if success else "Failed"))

	if _export_dialog_controller.has_method("update_progress"):
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
	if _export_dialog_controller.has_method("hide_progress"):
		_export_dialog_controller.hide_progress()

func _show_error_dialog(title: String, message: String) -> void:
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

func _show_info_dialog(title: String, message: String) -> void:
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
