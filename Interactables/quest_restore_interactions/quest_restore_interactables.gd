extends CanvasLayer
signal yes_pressed
signal no_pressed
@onready var button_yes: Button = $VBoxContainer/Button
@onready var button_no: Button = $VBoxContainer/Button2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110 # above the HUD and the touch controls (layer 100)
	button_yes.pressed.connect( _on_yes_pressed )
	button_no.pressed.connect( _on_no_pressed )
	hide_prompt()

# Touch screen: a tap on a button counts as pressing it
func _input( event: InputEvent ) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		if button_yes.get_global_rect().has_point( event.position ):
			_on_yes_pressed()
			get_viewport().set_input_as_handled()
		elif button_no.get_global_rect().has_point( event.position ):
			_on_no_pressed()
			get_viewport().set_input_as_handled()

func show_prompt() -> void:
	visible = true
	get_tree().paused = true
	button_yes.grab_focus()
	var touch := get_node_or_null("/root/TouchControls")
	if touch:
		touch.suppressed = true

func hide_prompt() -> void:
	visible = false
	get_tree().paused = false
	var touch := get_node_or_null("/root/TouchControls")
	if touch:
		touch.suppressed = false

func _on_yes_pressed() -> void:
	if not visible: # ignore a duplicate press
		return
	hide_prompt()
	yes_pressed.emit()

func _on_no_pressed() -> void:
	if not visible:
		return
	hide_prompt()
	no_pressed.emit()
