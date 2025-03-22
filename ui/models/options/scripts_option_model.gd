@tool
extends BaseOptionModel
class_name ScriptsOptionModel

"""
ScriptsOptionModel represents the data model for the scripts export option.
It configures the option to handle inclusion of script source code in the export.
"""

func _init():
	"""
	Initialize with specific settings for the scripts option.
	"""
	super._init(
		"Export Scripts",
		"Include script source code in the export",
		false
	)
