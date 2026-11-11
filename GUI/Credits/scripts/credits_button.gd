extends StyledButton

@onready var credits_panel: CanvasLayer = get_tree().current_scene.get_node("CreditsPanel")
@onready var main_canvas: CanvasLayer = get_tree().current_scene.get_node("CanvasLayer")

# The look and the hover effect come from StyledButton, so this script only
# keeps what the Credits button actually does.

func _pressed() -> void:
	main_canvas.visible = false
	credits_panel.visible = true
