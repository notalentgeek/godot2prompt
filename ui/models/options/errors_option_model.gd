@tool
extends BaseOptionModel
class_name ErrorsOptionModel

"""
ErrorsOptionModel represents the data model for the errors inclusion option.
It configures the option to handle inclusion of recent errors in the export.
"""

func _init():
	"""
	Initialize with specific settings for the errors option.
	"""
	super._init(
		"Include Recent Errors",
		"Include recent error logs in the export",
		false
	)
