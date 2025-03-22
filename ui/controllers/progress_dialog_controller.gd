@tool
extends BaseController
class_name ProgressDialogController

"""
ProgressDialogController coordinates between the progress dialog model and view.
It handles the logic for updating progress and managing the dialog.
"""

func _init():
	"""
	Initialize the controller by creating model and view instances.
	"""
	super._init()
	_model = ProgressDialogModel.new()
	_view = ProgressDialogView.new(self)

func initialize(parent_control: Control) -> void:
	"""
	Initialize the controller with the parent control.

	Args:
		parent_control: The parent control to add the dialog to
	"""
	_view.initialize(parent_control)

func show_progress() -> void:
	"""
	Show the progress dialog.
	"""
	_view.show_progress()

func hide_progress() -> void:
	"""
	Hide the progress dialog.
	"""
	_view.hide_progress()

func update_progress(progress: int, message: String) -> void:
	"""
	Update the progress and status message.

	Args:
		progress: The new progress value (0-100)
		message: The new status message
	"""
	_model.update_progress(progress, message)

func reset_progress() -> void:
	"""
	Reset the progress to initial state.
	"""
	_model.reset()
