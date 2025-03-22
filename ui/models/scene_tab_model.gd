@tool
extends BaseModel
class_name SceneTabModel

"""
SceneTabModel represents the data model for the scene tab.
It manages scene selection state and data.
"""

# Specific signals
signal scene_changed()

# The state maintained by this model is minimal as most of the
# scene hierarchy and selection state is managed by the Tree control.
# However, in a more complex application, this model would manage more data.

func _init():
	"""
	Initialize the scene tab model.
	"""
	super._init()

func notify_scene_changed() -> void:
	"""
	Notify observers that the scene has changed.
	"""
	emit_signal("scene_changed")
	notify_changed()  # Notify BaseModel observers
