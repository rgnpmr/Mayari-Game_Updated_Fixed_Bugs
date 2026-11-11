extends CanvasLayer
signal yes_pressed
signal no_pressed
@onready var button_yes: Button = $VBoxContainer/Button
@onready var button_no: Button = $VBoxContainer/Button2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	button_yes.pressed.connect( _on_yes_pressed )
	button_no.pressed.connect( _on_no_pressed )
	hide_prompt()

func show_prompt() -> void:
	visible = true
	get_tree().paused = true
	button_yes.grab_focus()

func hide_prompt() -> void:
	visible = false
	get_tree().paused = false

func _on_yes_pressed() -> void:
	hide_prompt()
	yes_pressed.emit()

func _on_no_pressed() -> void:
	hide_prompt()
	no_pressed.emit()
