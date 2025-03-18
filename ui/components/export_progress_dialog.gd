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
        # Create and configure dialog
        progress_dialog = AcceptDialog.new()
        parent_control.add_child(progress_dialog)

        # Configure basic dialog properties
        progress_dialog.title = "Exporting Scene"
        progress_dialog.min_size = Vector2(400, 150)
        progress_dialog.exclusive = false # Changed from true to avoid exclusive dialog conflicts

        # Add content container
        var vbox = VBoxContainer.new()
        vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
        vbox.custom_minimum_size = Vector2(300, 100)
        vbox.add_theme_constant_override("separation", 10) # Add space between elements
        progress_dialog.add_child(vbox)

        # Add status label
        status_label = Label.new()
        status_label.text = "Preparing export..."
        status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vbox.add_child(status_label)

        # Add progress bar
        progress_bar = ProgressBar.new()
        progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        progress_bar.custom_minimum_size = Vector2(0, 25) # Set a good height
        progress_bar.min_value = 0
        progress_bar.max_value = 100
        progress_bar.value = 0
        progress_bar.show_percentage = true
        vbox.add_child(progress_bar)

        # Hide the OK button during progress
        progress_dialog.get_ok_button().visible = false

        # Set the dialog to be unresizable
        progress_dialog.unresizable = false

func show_progress() -> void:
    if progress_dialog and parent_control:
        # Reset progress state
        progress_bar.value = 0
        status_label.text = "Initializing export..."

        # Process manually
        progress_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
        progress_dialog.set_process(true)
        progress_dialog.set_physics_process(true)

        # Hide OK button
        progress_dialog.get_ok_button().visible = false

        # Show the dialog
        progress_dialog.popup_centered()

        # Make sure it stays visible
        progress_dialog.visible = true

func hide_progress() -> void:
    if progress_dialog:
        # Make the OK button visible again
        progress_dialog.get_ok_button().visible = true

        # Hide the dialog
        progress_dialog.hide()

func update_progress(progress: int, message: String) -> void:
    if progress_dialog and progress_bar and status_label:
        # Don't skip intermediate values
        if progress > progress_bar.value + 20:
            # If big jump, add intermediate step
            var intermediate = progress_bar.value + 10
            progress_bar.value = intermediate

            # Small delay to show intermediate progress
            OS.delay_msec(50)

        # Update the progress bar
        progress_bar.value = progress

        # Update the status message
        status_label.text = message

        # No need to call queue_redraw - just ensure dialog is visible
        if progress_dialog.visible:
            # Instead of queue_redraw, force processing
            progress_dialog.set_process(true)
