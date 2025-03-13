@tool
extends RefCounted

# Save content to a file
func save_to_file(file_path: String, content: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		return true
	else:
		push_error("Failed to open file for writing: " + file_path)
		return false

# Load content from a file
func load_from_file(file_path: String) -> String:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			return content

	push_error("Failed to open file for reading: " + file_path)
	return ""
