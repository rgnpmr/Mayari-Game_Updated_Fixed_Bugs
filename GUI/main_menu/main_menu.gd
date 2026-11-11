extends Control

@onready var start_button: Button = $CanvasLayer/Control/CenterContainer/HBoxContainer/Button
@onready var continue_button: Button = $CanvasLayer/Control/CenterContainer/HBoxContainer/Button2

func _ready() -> void:
	ClockDisplay.hide_hud()

	# Continue only works when there is a saved game
	var can_continue : bool = SaveManager.has_save()
	continue_button.disabled = not can_continue
	if not can_continue:
		# Still clearly readable, but different from the buttons that work
		continue_button.modulate.a = 0.8
		continue_button.add_theme_color_override( "font_disabled_color", Color( 0.75, 0.75, 0.75, 1.0 ) )

	start_button.grab_focus()
