@tool
extends RefCounted

var progress_dialog: AcceptDialog = null
var progress_bar: ProgressBar = null
var status_label: Label = null
var parent_control: Control = null

func initialize(parent: Control) -> void:
    parent_control = parent

    # Create the progress dialog if it doesn't exist
    if progress_dialog == null:
        progress_dialog = AcceptDialog.new()
        parent_control.add_child(progress_dialog)

        # Configure the dialog
        progress_dialog.title = "Exporting Scene"
        progress_dialog.min_size = Vector2(400, 100)

        # Add a VBox to organize contents
        var vbox = VBoxContainer.new()
        vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
        progress_dialog.add_child(vbox)

        # Add a status label
        status_label = Label.new()
        status_label.text = "Preparing export..."
        vbox.add_child(status_label)

        # No progress bar implementation for now
        # We'll add it back in the future
