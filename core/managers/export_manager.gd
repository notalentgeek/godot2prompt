@tool
extends RefCounted

# Constants - Paths
const COMPOSITE_EXPORTER_PATH: String = "res://addons/godot2prompt/core/exporters/composite_exporter.gd"

# Constants - File Paths
const DEFAULT_EXPORT_PATH: String = "res://scene_hierarchy.txt"

# Core components
var _editor_interface: EditorInterface
var _error_manager
var _file_handler
var _scene_manager
var _screenshot_manager
var _ui_manager

# Exporters
var _exporters: Dictionary = {}

# Timers
var _completion_timer: Timer
var _export_timer: Timer

func initialize(
	editor_interface: EditorInterface,
	error_manager,
	file_handler,
	scene_manager,
	screenshot_manager,
	ui_manager
) -> void:
	_editor_interface = editor_interface
	_error_manager = error_manager
	_file_handler = file_handler
	_scene_manager = scene_manager
	_screenshot_manager = screenshot_manager
	_ui_manager = ui_manager

	_initialize_exporters()
	_connect_signals()

func set_timers(export_timer: Timer, completion_timer: Timer) -> void:
	_export_timer = export_timer
	_completion_timer = completion_timer

func _initialize_exporters() -> void:
	# Load and instantiate exporters alphabetically
	_exporters = {
		"code": load("res://addons/godot2prompt/core/exporters/code_exporter.gd").new(),
		"error": load("res://addons/godot2prompt/core/exporters/error_context_exporter.gd").new(),
		"project_config": load("res://addons/godot2prompt/core/exporters/project_config_exporter.gd").new(),
		"properties": load("res://addons/godot2prompt/core/exporters/properties_exporter.gd").new(),
		"screenshot": load("res://addons/godot2prompt/core/exporters/screenshot_exporter.gd").new(),
		"signal": load("res://addons/godot2prompt/core/exporters/signal_exporter.gd").new(),
		"tree": load("res://addons/godot2prompt/core/exporters/tree_exporter.gd").new()
	}

func _connect_signals() -> void:
	if not _ui_manager.is_connected("export_hierarchy", Callable(self, "_on_export_hierarchy")):
		_ui_manager.connect("export_hierarchy", Callable(self, "_on_export_hierarchy"))

# UI Methods
func show_export_dialog(root_node: Node) -> void:
	# Initialize the dialog with the root node
	_ui_manager.initialize(_editor_interface.get_base_control())
	_ui_manager.show_dialog(root_node)

func show_error_dialog(title: String, message: String) -> void:
	var error_dialog = AcceptDialog.new()
	error_dialog.title = title
	error_dialog.dialog_text = message

	var base_control = _editor_interface.get_base_control()
	base_control.add_child(error_dialog)
	error_dialog.popup_centered()

	error_dialog.connect("confirmed", Callable(self, "_on_dialog_closed").bind(error_dialog))
	error_dialog.connect("canceled", Callable(self, "_on_dialog_closed").bind(error_dialog))

func show_notification_dialog(title: String, message: String) -> void:
	var notification = AcceptDialog.new()
	notification.title = title
	notification.dialog_text = message

	var base_control = _editor_interface.get_base_control()
	base_control.add_child(notification)
	notification.popup_centered()

	notification.connect("confirmed", Callable(self, "_on_dialog_closed").bind(notification))

# Export Processing
func execute_quick_export(root: Node) -> void:
	# Initialize the dialog for quick export (to setup progress dialog)
	_ui_manager.initialize(_editor_interface.get_base_control())
	_ui_manager.show_progress()

	# Using a coroutine pattern for sequential progress updates
	_run_quick_export(root)

func _run_quick_export(root: Node) -> void:
	# Small delay to ensure the progress dialog is visible
	await _update_progress_with_delay(10, "Initializing quick export...", 0.1)

	# Take screenshot
	await _update_progress_with_delay(20, "Capturing screenshot...", 0.1)
	var screenshot_path = _screenshot_manager.capture_editor_screenshot(_editor_interface)

	# Default options for quick export (sorted alphabetically)
	var export_options = {
		"enabled_setting_categories": [],
		"include_errors": false,
		"include_project_settings": false,
		"include_properties": true,
		"include_scripts": false,
		"include_signals": false,
		"screenshot_path": screenshot_path
	}

	# Process the scene
	await _update_progress_with_delay(40, "Processing scene nodes...", 0.1)
	var node_data = _scene_manager.process_scene(
		root,
		export_options.include_properties,
		export_options.include_signals,
		[], # Empty error log as we're not including errors
		export_options.include_project_settings,
		export_options.enabled_setting_categories,
		export_options.screenshot_path
	)

	# Configure exporters
	await _update_progress_with_delay(60, "Setting up exporters...", 0.1)
	var exporter = _create_configured_exporter(export_options)

	# Generate and save output
	await _update_progress_with_delay(80, "Generating output text...", 0.1)
	var output_text = exporter.generate_output(node_data)

	await _update_progress_with_delay(90, "Saving to file...", 0.1)
	_file_handler.save_to_file(DEFAULT_EXPORT_PATH, output_text)

	# Complete progress
	_ui_manager.update_progress(100, "Export complete!")
	_completion_timer.start()

	# Show completion notification
	var completion_message = "Scene hierarchy exported to scene_hierarchy.txt"
	if not screenshot_path.is_empty():
		completion_message += "\nScreenshot saved to " + screenshot_path

	show_notification_dialog("Export Complete", completion_message)

# Export signal handler
func _on_export_hierarchy(
	selected_node: Node,
	include_scripts: bool,
	include_properties: bool,
	include_signals: bool,
	include_errors: bool,
	include_project_settings: bool,
	enabled_setting_categories: Array = [],
	include_screenshot: bool = false
) -> void:
	# Show progress immediately
	_ui_manager.show_progress()

	# Handle screenshot if requested
	if include_screenshot:
		_ui_manager.update_progress(30, "Creating scene visualization...")
		call_deferred("_process_export_with_screenshot",
			selected_node,
			include_scripts,
			include_properties,
			include_signals,
			include_errors,
			include_project_settings,
			enabled_setting_categories
		)
	else:
		# Process without screenshot
		_process_export(
			selected_node,
			include_scripts,
			include_properties,
			include_signals,
			include_errors,
			include_project_settings,
			enabled_setting_categories
		)

func _process_export_with_screenshot(
	selected_node: Node,
	include_scripts: bool,
	include_properties: bool,
	include_signals: bool,
	include_errors: bool,
	include_project_settings: bool,
	enabled_setting_categories: Array
) -> void:
	var screenshot_path = _screenshot_manager.capture_editor_screenshot(_editor_interface)

	_process_export(
		selected_node,
		include_scripts,
		include_properties,
		include_signals,
		include_errors,
		include_project_settings,
		enabled_setting_categories,
		screenshot_path
	)

func _process_export(
	selected_node: Node,
	include_scripts: bool,
	include_properties: bool,
	include_signals: bool,
	include_errors: bool,
	include_project_settings: bool,
	enabled_setting_categories: Array,
	screenshot_path: String = ""
) -> void:
	# Collect error logs if needed
	var error_log = []
	if include_errors:
		await _update_progress_with_delay(40, "Collecting error logs...", 0.1)
		error_log = _error_manager.get_errors()

	# Process the scene data
	await _update_progress_with_delay(50, "Processing scene nodes...", 0.1)

	# Validate scene manager and selected node
	if not _scene_manager or not _scene_manager.has_method("process_scene") or not selected_node:
		_handle_export_failure()
		return

	var node_data = _scene_manager.process_scene(
		selected_node,
		include_properties,
		include_signals,
		error_log,
		include_project_settings,
		enabled_setting_categories,
		screenshot_path
	)

	# Validate node data
	if not node_data:
		_handle_export_failure()
		return

	# Configure exporters based on options (sorted alphabetically)
	var export_options = {
		"enabled_setting_categories": enabled_setting_categories,
		"include_errors": include_errors,
		"include_project_settings": include_project_settings,
		"include_properties": include_properties,
		"include_scripts": include_scripts,
		"include_signals": include_signals,
		"screenshot_path": screenshot_path
	}

	await _update_progress_with_delay(60, "Setting up exporters...", 0.1)
	var exporter = _create_configured_exporter(export_options)

	# Generate and save output
	await _update_progress_with_delay(80, "Generating output text...", 0.1)
	var output_text = exporter.generate_output(node_data)

	await _update_progress_with_delay(90, "Saving to file...", 0.1)
	_file_handler.save_to_file(DEFAULT_EXPORT_PATH, output_text)

	# Finalize export
	_ui_manager.finalize_export()
	_completion_timer.start()

	# Show completion notification
	var completion_message = "Scene hierarchy exported to scene_hierarchy.txt"
	if not screenshot_path.is_empty():
		completion_message += "\nScene visualization saved to " + screenshot_path

	show_notification_dialog("Export Complete", completion_message)

func _handle_export_failure() -> void:
	_ui_manager.update_progress(100, "Export failed - could not process scene")
	_ui_manager.finalize_export()
	_completion_timer.start()

	show_error_dialog("Export Error", "Failed to process scene data for export.")

# Helper methods
func _create_configured_exporter(options: Dictionary) -> Object:
	var exporter = load(COMPOSITE_EXPORTER_PATH).new()

	# The tree exporter is always included for the base structure
	exporter.add_exporter(_exporters.tree)

	# Add other exporters based on options
	if options.include_properties and _exporters.properties:
		exporter.add_exporter(_exporters.properties)

	if options.include_signals and _exporters.signal:
		exporter.add_exporter(_exporters.signal )

	if options.include_scripts and _exporters.code:
		exporter.add_exporter(_exporters.code)

	if options.include_errors and _exporters.error:
		exporter.add_exporter(_exporters.error)

	if options.include_project_settings and not options.enabled_setting_categories.is_empty() and _exporters.project_config:
		exporter.add_exporter(_exporters.project_config)

	if not options.screenshot_path.is_empty() and _exporters.screenshot:
		exporter.add_exporter(_exporters.screenshot)

	return exporter

func _update_progress_with_delay(progress: int, message: String, delay: float) -> void:
	_ui_manager.update_progress(progress, message)

	# Create and use a timer since RefCounted doesn't have get_tree()
	var timer = Timer.new()
	_editor_interface.get_base_control().add_child(timer)
	timer.one_shot = true
	timer.wait_time = delay
	timer.start()

	# Wait for the timer to finish
	await timer.timeout

	# Clean up the timer
	timer.queue_free()

func _on_dialog_closed(dialog) -> void:
	if dialog and is_instance_valid(dialog):
		dialog.queue_free()
