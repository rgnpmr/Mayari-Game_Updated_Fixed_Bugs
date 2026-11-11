extends CanvasLayer

signal rest_pressed
signal cancel_pressed

@onready var button_rest: Button = $Control/VBoxContainer/ButtonRest
@onready var button_cancel: Button = $Control/VBoxContainer/ButtonCancel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110 # above the HUD and the touch controls (layer 100)
	button_rest.pressed.connect( _on_rest_pressed )
	button_cancel.pressed.connect( _on_cancel_pressed )
	hide_prompt()

# Touch screen: a tap on a button counts as pressing it
func _input( event: InputEvent ) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		if button_rest.get_global_rect().has_point( event.position ):
			_on_rest_pressed()
			get_viewport().set_input_as_handled()
		elif button_cancel.get_global_rect().has_point( event.position ):
			_on_cancel_pressed()
			get_viewport().set_input_as_handled()

func show_prompt() -> void:
	visible = true
	get_tree().paused = true
	button_rest.grab_focus()
	var touch := get_node_or_null("/root/TouchControls")
	if touch:
		touch.suppressed = true

func hide_prompt() -> void:
	visible = false
	get_tree().paused = false
	var touch := get_node_or_null("/root/TouchControls")
	if touch:
		touch.suppressed = false

func _on_rest_pressed() -> void:
	if not visible: # ignore a duplicate press from the emulated mouse click
		return
	hide_prompt()
	rest_pressed.emit()

func _on_cancel_pressed() -> void:
	if not visible:
		return
	hide_prompt()
	cancel_pressed.emit()
