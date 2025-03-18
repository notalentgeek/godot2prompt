@tool
extends RefCounted

signal export_hierarchy(selected_node, include_scripts, include_properties, include_signals, include_errors, include_project_settings, enabled_setting_categories, include_screenshot)
signal export_progress(progress, message)

# Core UI components
var dialog: Window = null
var current_root: Node = null
var progress_dialog = null

# Component managers
var scene_tab_manager = null
var options_tab_manager = null
var tree_selection_manager = null

func initialize(parent_control: Control) -> void:
	# Create the dialog if it doesn't exist
	if dialog == null:
		# Use AcceptDialog instead of ConfirmationDialog for more customization
		dialog = AcceptDialog.new()
		parent_control.add_child(dialog)

		# Configure the dialog
		dialog.title = "Scene to Prompt"
		dialog.min_size = Vector2(500, 500) # Larger dialog size for categories

		# Create main container with tabs
		var main_tabs = TabContainer.new()
		main_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
		dialog.add_child(main_tabs)

		# Initialize scene tab manager
		scene_tab_manager = load("res://addons/godot2prompt/ui/components/scene_tab_manager.gd").new()
		var scene_tab = scene_tab_manager.create_scene_tab()
		main_tabs.add_child(scene_tab)
		main_tabs.set_tab_title(0, "Scene")

		# Initialize tree selection manager (works with the scene tab's tree)
		tree_selection_manager = load("res://addons/godot2prompt/ui/components/tree_selection_manager.gd").new()
		tree_selection_manager.initialize(scene_tab_manager.get_tree())

		# Initialize options tab manager
		options_tab_manager = load("res://addons/godot2prompt/ui/components/options_tab_manager.gd").new()
		var options_tab = options_tab_manager.create_options_tab()
		main_tabs.add_child(options_tab)
		main_tabs.set_tab_title(1, "Options")

		# Initialize progress dialog
		# Fix: Load the script and create an instance properly
		var progress_dialog_script = load("res://addons/godot2prompt/ui/components/export_progress_dialog.gd")
		progress_dialog = progress_dialog_script.new()
		progress_dialog.initialize(parent_control)
		print("Progress dialog initialized")

		# Setup dialog buttons
		dialog.get_ok_button().text = "Export"
		var cancel_button = dialog.add_cancel_button("Cancel")

		# Connect signals
		dialog.connect("confirmed", Callable(self, "_on_export_confirmed"))
		dialog.connect("canceled", Callable(self, "_on_canceled"))

func show_dialog(root_node: Node) -> void:
	if dialog:
		current_root = root_node

		# Initialize the tree with the root node
		scene_tab_manager.clear_tree()
		tree_selection_manager.initialize_tree_with_root(root_node)

		# Populate settings categories in options tab
		options_tab_manager.populate_settings_categories()

		# Show the dialog
		dialog.popup_centered()

func _on_export_confirmed() -> void:
	print("Export confirmed, showing progress dialog")
	show_progress() # Show progress dialog immediately when export is confirmed

	# Get options from the options tab manager
	var export_options = options_tab_manager.get_export_options()

	# Get enabled setting categories if project settings are included
	var enabled_setting_categories = []
	if export_options.include_project_settings:
		enabled_setting_categories = options_tab_manager.get_enabled_setting_categories()

	# Find the highest selected node in the hierarchy
	var selected_node = tree_selection_manager.find_highest_selected_node()

	if selected_node:
		emit_signal("export_hierarchy",
			selected_node,
			export_options.include_scripts,
			export_options.include_properties,
			export_options.include_signals,
			export_options.include_errors,
			export_options.include_project_settings,
			enabled_setting_categories,
			export_options.include_screenshot)

	current_root = null

func _on_canceled() -> void:
	current_root = null

# Progress dialog control methods
func show_progress() -> void:
	print("Showing progress dialog")
	if progress_dialog:
		progress_dialog.show_progress()
		print("Progress dialog show_progress called")
	else:
		print("Error: progress_dialog is null")

func hide_progress_dialog() -> void:
	print("Hiding progress dialog")
	if progress_dialog:
		progress_dialog.hide_progress()
	else:
		print("Error: progress_dialog is null when trying to hide")

func update_progress(progress: int, message: String) -> void:
	print("Updating progress: ", progress, "% - ", message)
	if progress_dialog:
		progress_dialog.update_progress(progress, message)
	else:
		print("Error: progress_dialog is null when updating progress")

func finalize_export() -> void:
	print("Finalizing export")
	if progress_dialog:
		progress_dialog.update_progress(100, "Export completed!")
	else:
		print("Error: progress_dialog is null when finalizing")

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Cleanup
		if dialog and is_instance_valid(dialog):
			dialog.queue_free()
