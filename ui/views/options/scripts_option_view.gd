@tool
extends BaseOptionView
class_name ScriptsOptionView

"""
ScriptsOptionView provides the UI view for the scripts export option.
It creates and manages the checkbox for including script source code in the export.
"""

func _init():
	"""
	Initialize with a new scripts option model.
	"""
	super._init(ScriptsOptionModel.new())
