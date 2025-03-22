@tool
extends RefCounted
class_name ProgressDialogView

"""
ProgressDialogView creates and manages the UI for the export progress dialog.
It displays the current progress and status messages.
"""

# Constants
const DIALOG_MIN_SIZE: Vector2 = Vector2(400, 150)
const DIALOG_TITLE: String = "Exporting Scene"
const PROGRESS_BAR_HEIGHT: int = 25
const PROGRESS_MAX: int = 100
const PROGRESS_MIN: int = 0
const VBOX_MIN_SIZE: Vector2 = Vector2(300, 100)
const VBOX_SEPARATION: int = 10

# UI components
var _controller = null
var parent_control: Control = null
var progress_bar: ProgressBar = null
var progress_dialog: AcceptDialog = null
var status_label: Label = null

func _init(controller):
	"""
	Initialize the progress dialog view with a reference to its controller.

	Args:
		controller: The ProgressDialogController instance
	"""
	_controller = controller

func initialize(parent: Control) -> void:
	"""
	Initialize the dialog with the parent control.

	Args:
		parent: The parent control to add the dialog to
	"""
	parent_control = parent

	# Create the progress dialog if it doesn't exist
	if progress_dialog == null:
		_create_dialog()

func _create_dialog() -> void:
	"""
	Create and configure the progress dialog and its components.
	"""
	# Create and configure dialog
	progress_dialog = AcceptDialog.new()
	parent_control.add_child(progress_dialog)

	# Configure basic dialog properties
	progress_dialog.title = DIALOG_TITLE
	progress_dialog.min_size = DIALOG_MIN_SIZE
	progress_dialog.exclusive = false # Avoid exclusive dialog conflicts
	progress_dialog.unresizable = false

	# Add content container
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = VBOX_MIN_SIZE
	vbox.add_theme_constant_override("separation", VBOX_SEPARATION)
	progress_dialog.add_child(vbox)

	# Add status label
	status_label = Label.new()
	status_label.text = "Preparing export..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	# Add progress bar
	progress_bar = ProgressBar.new()
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.custom_minimum_size = Vector2(0, PROGRESS_BAR_HEIGHT)
	progress_bar.min_value = PROGRESS_MIN
	progress_bar.max_value = PROGRESS_MAX
	progress_bar.value = PROGRESS_MIN
	progress_bar.show_percentage = true
	vbox.add_child(progress_bar)

	# Hide the OK button during progress
	progress_dialog.get_ok_button().visible = false

	# Connect to model changes
	_controller.get_model().progress_updated.connect(_on_progress_updated)

func show_progress() -> void:
	"""
	Show the progress dialog.
	"""
	if not progress_dialog or not parent_control:
		return

	# Reset progress state through the controller
	_controller.reset_progress()

	# Process manually to ensure dialog updates
	progress_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	progress_dialog.set_process(true)
	progress_dialog.set_physics_process(true)

	# Hide OK button
	progress_dialog.get_ok_button().visible = false

	# Show the dialog
	progress_dialog.popup_centered()

	# Make sure it stays visible
	progress_dialog.visible = true

func hide_progress() -> void:
	"""
	Hide the progress dialog.
	"""
	if not progress_dialog:
		return

	# Make the OK button visible again
	progress_dialog.get_ok_button().visible = true

	# Hide the dialog
	progress_dialog.hide()

func _on_progress_updated(progress: int, message: String) -> void:
	"""
	Update the UI when progress changes in the model.

	Args:
		progress: The new progress value
		message: The new status message
	"""
	if not progress_dialog or not progress_bar or not status_label:
		return

	# Handle large jumps in progress with intermediate steps
	if progress > progress_bar.value + 20:
		# If big jump, add intermediate step
		var intermediate = progress_bar.value + 10
		progress_bar.value = intermediate

		# Small delay to show intermediate progress
		OS.delay_msec(50)

	# Update the progress bar
	progress_bar.value = progress

	# Update the status message
	status_label.text = message

	# Force processing to ensure UI updates
	if progress_dialog.visible:
		progress_dialog.set_process(true)
