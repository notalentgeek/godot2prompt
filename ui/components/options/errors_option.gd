@tool
extends RefCounted

var include_errors_checkbox: CheckBox = null

func create_option() -> Control:
	include_errors_checkbox = CheckBox.new()
	include_errors_checkbox.text = "Include Recent Errors"
	include_errors_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	include_errors_checkbox.set_pressed(false)
	include_errors_checkbox.tooltip_text = "Include recent error logs in the export"

	return include_errors_checkbox

func is_enabled() -> bool:
	return include_errors_checkbox.is_pressed()
