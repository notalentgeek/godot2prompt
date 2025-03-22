@tool
extends BaseOptionView
class_name SignalsOptionView

"""
SignalsOptionView provides the UI view for the signals export option.
It creates and manages the checkbox for including signal connections in the export.
"""

func _init():
	"""
	Initialize with a new signals option model.
	"""
	super._init(SignalsOptionModel.new())
