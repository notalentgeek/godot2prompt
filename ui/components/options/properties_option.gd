@tool
extends RefCounted

var include_properties_checkbox: CheckBox = null

func create_option() -> Control:
	include_properties_checkbox = CheckBox.new()
	include_properties_checkbox.text = "Export Properties"
	include_properties_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	include_properties_checkbox.set_pressed(false)
	include_properties_checkbox.tooltip_text = "Include node properties in the export"

	return include_properties_checkbox

func is_enabled() -> bool:
	return include_properties_checkbox.is_pressed()
