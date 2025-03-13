@tool
extends RefCounted

signal export_with_scripts(root_node, include_properties)
signal export_without_scripts(root_node, include_properties)

var dialog: ConfirmationDialog = null
var current_root: Node = null
var include_properties_checkbox: CheckBox = null

func initialize(parent_control: Control) -> void:
	# Create the dialog if it doesn't exist
	if dialog == null:
		dialog = ConfirmationDialog.new()
		parent_control.add_child(dialog)

		# Configure the dialog
		dialog.title = "Export Scene Hierarchy"
		dialog.dialog_text = "Export Options:"
		dialog.dialog_hide_on_ok = true
		dialog.get_ok_button().text = "Include Scripts"

		# Create VBox for options
		var vbox = VBoxContainer.new()
		vbox.custom_minimum_size = Vector2(300, 100)
		dialog.add_child(vbox)

		# Add some space after the dialog text
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		vbox.add_child(spacer)

		# Add property checkbox
		include_properties_checkbox = CheckBox.new()
		include_properties_checkbox.text = "Include Node Properties"
		include_properties_checkbox.set_pressed(true)
		vbox.add_child(include_properties_checkbox)

		# Add the "No Scripts" button
		var no_button = dialog.add_button("Exclude Scripts", false, "export_without_scripts")
		no_button.connect("pressed", Callable(self, "_on_no_pressed"))

		# Connect the confirmed signal
		dialog.connect("confirmed", Callable(self, "_on_yes_pressed"))
		dialog.connect("canceled", Callable(self, "_on_canceled"))

func show_dialog(root_node: Node) -> void:
	if dialog:
		current_root = root_node
		dialog.popup_centered()

func _on_yes_pressed() -> void:
	if current_root:
		var include_properties = include_properties_checkbox.is_pressed()
		emit_signal("export_with_scripts", current_root, include_properties)
		current_root = null

func _on_no_pressed() -> void:
	if dialog:
		dialog.hide()

	if current_root:
		var include_properties = include_properties_checkbox.is_pressed()
		emit_signal("export_without_scripts", current_root, include_properties)
		current_root = null

func _on_canceled() -> void:
	current_root = null

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Cleanup
		if dialog and is_instance_valid(dialog):
			dialog.queue_free()
