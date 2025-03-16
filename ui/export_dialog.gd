@tool
extends RefCounted

signal export_hierarchy(selected_node, include_scripts, include_properties, include_signals, include_errors, include_project_settings, enabled_setting_categories)

var dialog: Window = null
var current_root: Node = null
var include_scripts_checkbox: CheckBox = null
var include_properties_checkbox: CheckBox = null
var include_signals_checkbox: CheckBox = null
var include_errors_checkbox: CheckBox = null
var include_project_settings_checkbox: CheckBox = null
var settings_categories_container: VBoxContainer = null
var categories_label: Label = null
var categories_scroll: ScrollContainer = null
var category_checkboxes = {} # Dictionary of category name to checkbox
var tree: Tree = null
var root_item: TreeItem = null
var node_items = {} # Dictionary to map TreeItems to Nodes

# Special category names that should be capitalized differently
var special_capitalizations = {
	"gui": "GUI",
	"xr": "XR",
	"3d": "3D",
	"2d": "2D",
	"gdscript": "GDScript",
	"tls": "TLS",
	"ssl": "SSL",
	"vram": "VRAM",
	"api": "API",
	"csg": "CSG",
	"bvh": "BVH",
	"wp8": "WP8",
	"macos": "macOS",
	"ios": "iOS",
	"html5": "HTML5",
	"x11": "X11",
	"osx": "OSX",
	"tcp": "TCP",
	"udp": "UDP",
	"http": "HTTP",
	"url": "URL",
	"cpu": "CPU",
	"gpu": "GPU",
	"gles2": "GLES2",
	"gles3": "GLES3",
	"fft": "FFT",
	"vsync": "VSync",
	"ar": "AR",
	"vr": "VR",
	"ui": "UI"
}

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

		# Tab 1: Scene Selection
		var scene_tab = VBoxContainer.new()
		scene_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scene_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_tabs.add_child(scene_tab)
		main_tabs.set_tab_title(0, "Scene")

		# Add dialog header label
		var header_label = Label.new()
		header_label.text = "Select nodes to include in export:"
		scene_tab.add_child(header_label)

		# Add help text
		var help_label = Label.new()
		help_label.text = "Selecting a node will automatically include all its children"
		help_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		scene_tab.add_child(help_label)

		# Add tree for scene hierarchy
		tree = Tree.new()
		tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tree.custom_minimum_size = Vector2(0, 250)
		tree.allow_rmb_select = false
		tree.select_mode = Tree.SELECT_MULTI
		tree.connect("item_selected", Callable(self, "_on_item_selected"))
		scene_tab.add_child(tree)

		# Tab 2: Export Options
		var options_tab = VBoxContainer.new()
		options_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_tabs.add_child(options_tab)
		main_tabs.set_tab_title(1, "Options")

		# Add export options section
		var options_label = Label.new()
		options_label.text = "Export options:"
		options_tab.add_child(options_label)

		# Options grid container (2 columns for better layout)
		var options_grid = GridContainer.new()
		options_grid.columns = 2
		options_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options_tab.add_child(options_grid)

		# Add script checkbox - all checkboxes unchecked by default
		include_scripts_checkbox = CheckBox.new()
		include_scripts_checkbox.text = "Export Scripts"
		include_scripts_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		include_scripts_checkbox.set_pressed(false)
		options_grid.add_child(include_scripts_checkbox)

		# Add property checkbox
		include_properties_checkbox = CheckBox.new()
		include_properties_checkbox.text = "Export Properties"
		include_properties_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		include_properties_checkbox.set_pressed(false)
		options_grid.add_child(include_properties_checkbox)

		# Add signals checkbox
		include_signals_checkbox = CheckBox.new()
		include_signals_checkbox.text = "Export Signals"
		include_signals_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		include_signals_checkbox.set_pressed(false)
		options_grid.add_child(include_signals_checkbox)

		# Add errors checkbox
		include_errors_checkbox = CheckBox.new()
		include_errors_checkbox.text = "Include Recent Errors"
		include_errors_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		include_errors_checkbox.set_pressed(false)
		options_grid.add_child(include_errors_checkbox)

		# Add project settings checkbox with connection to show/hide categories
		include_project_settings_checkbox = CheckBox.new()
		include_project_settings_checkbox.text = "Include Project Settings"
		include_project_settings_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		include_project_settings_checkbox.set_pressed(false)
		include_project_settings_checkbox.connect("toggled", Callable(self, "_on_project_settings_toggled"))
		options_grid.add_child(include_project_settings_checkbox)

		# Add spacer after main options
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		options_tab.add_child(spacer)

		# Add container for settings categories
		categories_label = Label.new()
		categories_label.text = "Project Settings Categories:"
		options_tab.add_child(categories_label)

		# Scrollable container for categories (useful if there are many)
		categories_scroll = ScrollContainer.new()
		categories_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		categories_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		options_tab.add_child(categories_scroll)

		settings_categories_container = VBoxContainer.new()
		settings_categories_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		categories_scroll.add_child(settings_categories_container)

		# Initially hide the categories since the checkbox is not checked
		categories_label.visible = false
		categories_scroll.visible = false

		# Setup dialog buttons
		dialog.get_ok_button().text = "Export"
		var cancel_button = dialog.add_cancel_button("Cancel")

		# Connect signals
		dialog.connect("confirmed", Callable(self, "_on_export_confirmed"))
		dialog.connect("canceled", Callable(self, "_on_canceled"))

func show_dialog(root_node: Node) -> void:
	if dialog:
		current_root = root_node

		# Clear previous tree
		tree.clear()
		node_items.clear()

		# Populate the tree
		root_item = tree.create_item()
		root_item.set_text(0, root_node.name + " (" + root_node.get_class() + ")")
		root_item.set_metadata(0, root_node)
		node_items[root_node] = root_item

		# Recursively add all children
		_add_children_to_tree(root_node, root_item)

		# Expand the root by default
		root_item.set_collapsed(false)

		# Select the root by default
		root_item.select(0)
		_select_children(root_item)

		# Populate settings categories
		_populate_settings_categories()

		# Update category visibility based on checkbox state
		_on_project_settings_toggled(include_project_settings_checkbox.is_pressed())

		# Show the dialog
		dialog.popup_centered()

# Function to properly format category name
func _format_category_name(category: String) -> String:
	# Check if the category is in our special cases dictionary first
	if category.to_lower() in special_capitalizations:
		return special_capitalizations[category.to_lower()]

	# Otherwise capitalize the first letter of each word
	var words = category.split("_")
	for i in range(words.size()):
		words[i] = words[i].capitalize()

	return " ".join(words)

func _populate_settings_categories() -> void:
	# Clear existing categories
	for child in settings_categories_container.get_children():
		child.queue_free()

	category_checkboxes.clear()

	# Load the project settings exporter
	var ProjectConfigExporter = load("res://addons/godot2prompt/core/exporters/project_config_exporter.gd")

	# Get available categories
	var categories = ProjectConfigExporter.get_setting_categories()

	print("Found categories: ", categories)

	# Create a checkbox for each category
	for category in categories:
		var checkbox = CheckBox.new()
		checkbox.text = _format_category_name(category)
		checkbox.set_pressed(true) # All categories checked by default
		settings_categories_container.add_child(checkbox)

		# Store reference to checkbox
		category_checkboxes[category] = checkbox

func _on_project_settings_toggled(button_pressed: bool) -> void:
	# Show/hide the categories section based on checkbox state
	categories_label.visible = button_pressed
	categories_scroll.visible = button_pressed

	# If toggling on and no categories populated, populate them now
	if button_pressed and category_checkboxes.size() == 0:
		_populate_settings_categories()

func _add_children_to_tree(node: Node, parent_item: TreeItem) -> void:
	for child in node.get_children():
		var item = tree.create_item(parent_item)
		item.set_text(0, child.name + " (" + child.get_class() + ")")
		item.set_metadata(0, child)
		node_items[child] = item

		# Recursively add children
		_add_children_to_tree(child, item)

func _on_item_selected() -> void:
	var selected_item = tree.get_selected()

	# Toggle children selection based on parent
	if selected_item.is_selected(0):
		_select_children(selected_item)
	else:
		_deselect_children(selected_item)

func _select_children(item: TreeItem) -> void:
	var child = item.get_first_child()
	while child:
		child.select(0)
		_select_children(child)
		child = child.get_next()

func _deselect_children(item: TreeItem) -> void:
	var child = item.get_first_child()
	while child:
		child.deselect(0)
		_deselect_children(child)
		child = child.get_next()

func _on_export_confirmed() -> void:
	# Get options
	var include_scripts = include_scripts_checkbox.is_pressed()
	var include_properties = include_properties_checkbox.is_pressed()
	var include_signals = include_signals_checkbox.is_pressed()
	var include_errors = include_errors_checkbox.is_pressed()
	var include_project_settings = include_project_settings_checkbox.is_pressed()

	# Get enabled setting categories
	var enabled_setting_categories = []
	if include_project_settings:
		for category in category_checkboxes.keys():
			if category_checkboxes[category].is_pressed():
				enabled_setting_categories.append(category)

	# Find the highest selected node in the hierarchy
	var selected_node = _find_highest_selected_node()

	if selected_node:
		emit_signal("export_hierarchy", selected_node, include_scripts, include_properties,
					include_signals, include_errors, include_project_settings,
					enabled_setting_categories)

	current_root = null

func _find_highest_selected_node() -> Node:
	# Start with the root item
	var item = root_item

	# If root is selected, return the root node
	if item.is_selected(0):
		return current_root

	# Otherwise search for the highest selected node
	return _find_highest_selected_in_children(item)

func _find_highest_selected_in_children(item: TreeItem) -> Node:
	var child = item.get_first_child()
	while child:
		if child.is_selected(0):
			return child.get_metadata(0)

		var selected_descendant = _find_highest_selected_in_children(child)
		if selected_descendant:
			return selected_descendant

		child = child.get_next()

	return null

func _on_canceled() -> void:
	current_root = null

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Cleanup
		if dialog and is_instance_valid(dialog):
			dialog.queue_free()
