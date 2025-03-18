@tool
extends "res://addons/godot2prompt/ui/components/options/base_option.gd"

func _init():
	option_text = "Export Signals"
	option_tooltip = "Include signal connections in the export"
	default_state = false
