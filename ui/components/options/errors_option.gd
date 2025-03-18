@tool
extends "res://addons/godot2prompt/ui/components/options/base_option.gd"

func _init():
	option_text = "Include Recent Errors"
	option_tooltip = "Include recent error logs in the export"
	default_state = false
