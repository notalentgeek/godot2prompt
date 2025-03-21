@tool
extends RefCounted
class_name FileSystem

"""
FileSystem provides utilities for reading and writing files.
It wraps Godot's FileAccess API to provide simplified file operations.
"""

# Error Messages
const ERROR_READ: String = "Failed to open file for reading: %s"
const ERROR_WRITE: String = "Failed to open file for writing: %s"

func save_content(file_path: String, content: String) -> bool:
	"""
	Saves string content to a file.

	Args:
		file_path: The path where the file should be saved
		content: The string content to write to the file

	Returns:
		True if the operation was successful, otherwise False
	"""
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if not file:
		push_error(ERROR_WRITE % file_path)
		return false

	file.store_string(content)
	file.close()
	return true

func load_content(file_path: String) -> String:
	"""
	Loads string content from a file.

	Args:
		file_path: The path to the file to read

	Returns:
		The file content as a string, or an empty string if the file
		couldn't be read
	"""
	if not FileAccess.file_exists(file_path):
		push_error(ERROR_READ % file_path)
		return ""

	var file = FileAccess.open(file_path, FileAccess.READ)

	if not file:
		push_error(ERROR_READ % file_path)
		return ""

	var content = file.get_as_text()
	file.close()
	return content
