@tool
extends RefCounted
class_name SceneTabController

"""
SceneTabController coordinates between the scene tab model and view.
It handles user interactions with the scene hierarchy.
"""

# Model and view references
var _model: SceneTabModel
var _view: SceneTabView

func _init():
	"""
	Initialize the controller by creating model and view instances.
	"""
	_model = SceneTabModel.new()
	_view = SceneTabView.new(self)

func create_scene_tab() -> Control:
	"""
	Create and return the scene tab control.

	Returns:
		The root control for the scene tab
	"""
	return _view.create_view()

func get_tree() -> Tree:
	"""
	Get the tree control for external usage.

	Returns:
		The Tree control instance
	"""
	return _view.get_tree()

func clear_tree() -> void:
	"""
	Clear the tree for reuse.
	"""
	_view.clear_tree()
