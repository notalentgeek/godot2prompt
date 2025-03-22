@tool
extends BaseOptionView
class_name PropertiesOptionView

"""
PropertiesOptionView provides the UI view for the properties export option.
It creates and manages the checkbox for including node properties in the export.
"""

func _init():
	"""
	Initialize with a new properties option model.
	"""
	super._init(PropertiesOptionModel.new())
