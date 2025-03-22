@tool
extends RefCounted
class_name BaseController

"""
BaseController serves as the base class for all controllers in the MVC pattern.
It provides common functionality and establishes a consistent pattern for controllers.
"""

# Member variables for derived classes to use
var _model = null
var _view = null

func _init():
	"""
	Initialize the base controller.
	This is meant to be overridden by derived classes.
	"""
	pass

func get_model():
	"""
	Get the model associated with this controller.

	Returns:
		The model instance
	"""
	return _model

func get_view():
	"""
	Get the view associated with this controller.

	Returns:
		The view instance
	"""
	return _view
