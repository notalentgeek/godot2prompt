@tool
extends RefCounted

var include_screenshot_checkbox: CheckBox = null

func create_option() -> Control:
	include_screenshot_checkbox = CheckBox.new()
	include_screenshot_checkbox.text = "Include Screenshot"
	include_screenshot_checkbox.tooltip_text = "Captures the current editor viewport"
	include_screenshot_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	include_screenshot_checkbox.set_pressed(false)

	return include_screenshot_checkbox

func is_enabled() -> bool:
	return include_screenshot_checkbox.is_pressed()
