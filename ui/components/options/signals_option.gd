@tool
extends RefCounted

var include_signals_checkbox: CheckBox = null

func create_option() -> Control:
	include_signals_checkbox = CheckBox.new()
	include_signals_checkbox.text = "Export Signals"
	include_signals_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	include_signals_checkbox.set_pressed(false)
	include_signals_checkbox.tooltip_text = "Include signal connections in the export"

	return include_signals_checkbox

func is_enabled() -> bool:
	return include_signals_checkbox.is_pressed()
