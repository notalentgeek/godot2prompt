@tool
extends "res://addons/godot2prompt/ui/components/options/base_option.gd"

func _init():
	option_text = "Export Scripts"
	option_tooltip = "Include script source code in the export"
	default_state = false
