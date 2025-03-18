@tool
extends RefCounted

var progress_dialog: AcceptDialog = null
var progress_bar: ProgressBar = null
var status_label: Label = null
var parent_control: Control = null

# Initialize the progress dialog
func initialize(p_parent_control: Control) -> void:
	parent_control = p_parent_control

	# Create the dialog if it doesn't exist
	if progress_dialog == null:
		progress_dialog = AcceptDialog.new()
		parent_control.add_child(progress_dialog)

		# Configure the dialog
		progress_dialog.title = "Exporting Scene..."
		progress_dialog.dialog_text = "" # We'll use a custom label instead
		progress_dialog.min_size = Vector2(350, 150)
		progress_dialog.exclusive = true
		progress_dialog.dialog_hide_on_ok = false # Prevent closing with OK

		# Create a container for our progress elements
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		progress_dialog.add_child(vbox)

		# Add status label
		status_label = Label.new()
		status_label.text = "Starting export process..."
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(status_label)

		# Add spacer
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		vbox.add_child(spacer)

		# Add progress bar
		progress_bar = ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = 100
		progress_bar.value = 0
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.custom_minimum_size = Vector2(300, 20)
		vbox.add_child(progress_bar)

# Show the progress dialog
func show_progress() -> void:
	if progress_dialog:
		# Reset progress
		progress_bar.value = 0
		status_label.text = "Starting export process..."

		# Show the dialog
		progress_dialog.popup_centered()

# Update progress
func update_progress(percentage: float, status: String = "") -> void:
	if progress_dialog and progress_dialog.visible:
		progress_bar.value = percentage

		if status:
			status_label.text = status

# Hide the progress dialog
func hide_progress() -> void:
	if progress_dialog and progress_dialog.visible:
		progress_dialog.hide()

# Clean up resources
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if progress_dialog and is_instance_valid(progress_dialog):
			progress_dialog.queue_free()
