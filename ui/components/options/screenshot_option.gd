@tool
extends "res://addons/godot2prompt/ui/components/options/base_option.gd"

func _init():
	option_text = "Include Screenshot"
	option_tooltip = "Captures the current editor viewport"
	default_state = false
