@tool
extends BaseOptionModel
class_name PropertiesOptionModel

"""
PropertiesOptionModel represents the data model for the properties export option.
It configures the option to handle inclusion of node properties in the export.
"""

func _init():
	"""
	Initialize with specific settings for the properties option.
	"""
	super._init(
		"Export Properties",
		"Include node properties in the export",
		false
	)
