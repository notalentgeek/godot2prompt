@tool
extends BaseOptionView
class_name ErrorsOptionView

"""
ErrorsOptionView provides the UI view for the errors inclusion option.
It creates and manages the checkbox for including errors in the export.
"""

func _init():
	"""
	Initialize with a new errors option model.
	"""
	super._init(ErrorsOptionModel.new())
