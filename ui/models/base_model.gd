@tool
extends RefCounted
class_name BaseModel

"""
BaseModel serves as the foundation for all model classes in the MVC pattern.
It provides common functionality and establishes a consistent pattern for models.
"""

# Common signals
signal changed()

func _init():
	"""
	Initialize the base model.
	This is meant to be overridden by derived classes.
	"""
	pass

func notify_changed() -> void:
	"""
	Notify observers that the model has changed.
	Derived classes should call this when their state changes.
	"""
	emit_signal("changed")
