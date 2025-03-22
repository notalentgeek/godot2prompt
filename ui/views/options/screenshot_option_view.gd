@tool
extends BaseOptionView
class_name ScreenshotOptionView

"""
ScreenshotOptionView provides the UI view for the screenshot inclusion option.
It creates and manages the checkbox for including editor screenshots in the export.
"""

func _init():
	"""
	Initialize with a new screenshot option model.
	"""
	super._init(ScreenshotOptionModel.new())
