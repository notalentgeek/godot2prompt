@tool
extends RefCounted
class_name SceneTabModel

"""
SceneTabModel represents the data model for the scene tab.
It manages scene selection state and data.
"""

# Signals
signal scene_changed()

# The state maintained by this model is minimal as most of the
# scene hierarchy and selection state is managed by the Tree control.
# However, in a more complex application, this model would manage more data.

func _init():
	"""
	Initialize the scene tab model.
	"""
	pass
