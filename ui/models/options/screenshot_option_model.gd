@tool
extends BaseOptionModel
class_name ScreenshotOptionModel

"""
ScreenshotOptionModel represents the data model for the screenshot inclusion option.
It configures the option to handle inclusion of editor screenshots in the export.
"""

func _init():
	"""
	Initialize with specific settings for the screenshot option.
	"""
	super._init(
		"Include Screenshot",
		"Captures the current editor viewport",
		false
	)
