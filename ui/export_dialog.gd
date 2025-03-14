@tool
extends RefCounted

signal export_hierarchy(selected_node, include_scripts, include_properties, include_signals)

var dialog: Window = null
var current_root: Node = null
var include_scripts_checkbox: CheckBox = null
var include_properties_checkbox: CheckBox = null
var include_signals_checkbox: CheckBox = null
var tree: Tree = null
var root_item: TreeItem = null
var node_items = {} # Dictionary to map TreeItems to Nodes

func initialize(parent_control: Control) -> void:
	# Create the dialog if it doesn't exist
	if dialog == null:
		# Use AcceptDialog instead of ConfirmationDialog for more customization
		dialog = AcceptDialog.new()
		parent_control.add_child(dialog)

		# Configure the dialog
		dialog.title = "Scene to Prompt"
		dialog.min_size = Vector2(500, 400) # Larger dialog size

		# Create main container
		var main_vbox = VBoxContainer.new()
		main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		dialog.add_child(main_vbox)

		# Add dialog header label
		var header_label = Label.new()
		header_label.text = "Select nodes to include in export:"
		main_vbox.add_child(header_label)

		# Add help text
		var help_label = Label.new()
		help_label.text = "Selecting a node will automatically include all its children"
		help_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		main_vbox.add_child(help_label)

		# Add tree for scene hierarchy
		tree = Tree.new()
		tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tree.custom_minimum_size = Vector2(0, 250)
		tree.allow_rmb_select = false
		tree.select_mode = Tree.SELECT_MULTI
		tree.connect("item_selected", Callable(self, "_on_item_selected"))
		main_vbox.add_child(tree)

		# Add export options section
		var options_label = Label.new()
		options_label.text = "Export options:"
		main_vbox.add_child(options_label)

		# Options grid container (3 columns for better layout)
		var options_grid = GridContainer.new()
		options_grid.columns = 2
		options_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vbox.add_child(options_grid)

		# Add script checkbox
		include_scripts_checkbox = CheckBox.new()
		include_scripts_checkbox.text = "Export Scripts"
		include_scripts_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		include_scripts_checkbox.set_pressed(true)
		options_grid.add_child(include_scripts_checkbox)

		# Add property checkbox
		include_properties_checkbox = CheckBox.new()
		include_properties_checkbox.text = "Export Properties"
		include_properties_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		include_properties_checkbox.set_pressed(true)
		options_grid.add_child(include_properties_checkbox)

		# Add signals checkbox
		include_signals_checkbox = CheckBox.new()
		include_signals_checkbox.text = "Export Signals"
		include_signals_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		include_signals_checkbox.set_pressed(true)
		options_grid.add_child(include_signals_checkbox)

		# Add spacer
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		main_vbox.add_child(spacer)

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

		# Show the dialog
		dialog.popup_centered()

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

	# Find the highest selected node in the hierarchy
	var selected_node = _find_highest_selected_node()

	if selected_node:
		emit_signal("export_hierarchy", selected_node, include_scripts, include_properties, include_signals)

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
