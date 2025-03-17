@tool
extends RefCounted

var include_scripts_checkbox: CheckBox = null

func create_option() -> Control:
	include_scripts_checkbox = CheckBox.new()
	include_scripts_checkbox.text = "Export Scripts"
	include_scripts_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	include_scripts_checkbox.set_pressed(false)
	include_scripts_checkbox.tooltip_text = "Include script source code in the export"

	return include_scripts_checkbox

func is_enabled() -> bool:
	return include_scripts_checkbox.is_pressed()
