extends StyledButton

const STORY_SCENE : PackedScene = preload( "res://Level/Story/intro_storytelling.tscn" )


func _pressed() -> void:
	release_focus()
	disabled = true

	SaveManager.reset_for_new_game()

	PlayerManager.add_player_instance()
	PlayerManager.pending_new_game_spawn = true

	get_tree().current_scene.get_node("CanvasLayer").visible = false
	get_tree().current_scene.get_node("TextureRect").visible = false

	ClockDisplay.hide_hud()  # keep hidden through the story scene

	var story = STORY_SCENE.instantiate()
	get_tree().current_scene.add_child( story )
	story.story_finished.connect( _on_story_finished )
	pass

func _on_story_finished() -> void:
	ClockDisplay.show_hud()  # reveal once story ends and gameplay begins
	LevelManager.load_new_level( "res://Level/Chapters/OpeningScene.tscn", "", Vector2.ZERO )
	pass
