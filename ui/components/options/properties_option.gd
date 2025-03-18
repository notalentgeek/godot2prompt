@tool
extends "res://addons/godot2prompt/ui/components/options/base_option.gd"

func _init():
	option_text = "Export Properties"
	option_tooltip = "Include node properties in the export"
	default_state = false
