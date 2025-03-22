@tool
extends BaseOptionModel
class_name SignalsOptionModel

"""
SignalsOptionModel represents the data model for the signals export option.
It configures the option to handle inclusion of signal connections in the export.
"""

func _init():
	"""
	Initialize with specific settings for the signals option.
	"""
	super._init(
		"Export Signals",
		"Include signal connections in the export",
		false
	)
