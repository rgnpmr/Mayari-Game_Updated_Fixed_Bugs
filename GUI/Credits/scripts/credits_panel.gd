extends CanvasLayer

@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton
@onready var main_canvas: CanvasLayer = get_tree().current_scene.get_node("CanvasLayer")

func _ready() -> void:
	visible = false
	close_button.pressed.connect( _on_close_pressed )

func _on_close_pressed() -> void:
	visible = false
	main_canvas.visible = true
