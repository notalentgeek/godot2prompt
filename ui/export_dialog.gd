@tool
extends RefCounted

signal export_with_scripts(root_node)
signal export_without_scripts(root_node)

var dialog: ConfirmationDialog = null
var current_root: Node = null

func initialize(parent_control: Control) -> void:
	# Create the dialog if it doesn't exist
	if dialog == null:
		dialog = ConfirmationDialog.new()
		parent_control.add_child(dialog)

		# Configure the dialog
		dialog.title = "Export Scene Hierarchy"
		dialog.dialog_text = "Include attached scripts in the export?"
		dialog.dialog_hide_on_ok = true
		dialog.get_ok_button().text = "Yes"

		# Add the "No" button
		var no_button = dialog.add_button("No", true, "export_without_scripts")
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
		emit_signal("export_with_scripts", current_root)
		current_root = null

func _on_no_pressed() -> void:
	if dialog:
		dialog.hide()

	if current_root:
		emit_signal("export_without_scripts", current_root)
		current_root = null

func _on_canceled() -> void:
	current_root = null

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Cleanup
		if dialog and is_instance_valid(dialog):
			dialog.queue_free()
