extends StyledButton

func _ready() -> void:
	apply_style()
	# Nothing to continue from yet: dim the button and block the click, so the
	# player isn't left on an empty screen when there is no save file.
	disabled = not FileAccess.file_exists( SaveManager.SAVE_PATH + SaveManager.SAVE_FILE )

func _pressed() -> void:
	get_tree().current_scene.get_node("CanvasLayer").visible = false
	get_tree().current_scene.get_node("TextureRect").visible = false

	PlayerManager.add_player_instance()
	SaveManager.load_game()
	PlayerHud.show_hud()
	TimeManager.start_clock()
