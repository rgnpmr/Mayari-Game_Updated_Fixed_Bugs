extends Node2D

func _ready() -> void:
	visible = false
	
	if PlayerManager.player == null:
		# Running this scene directly in the editor (no player exists yet at all)
		PlayerManager.add_player_instance()
		PlayerManager.set_player_position( global_position )
	elif PlayerManager.pending_new_game_spawn:
		# Came from the main menu's "Start" button
		PlayerManager.set_player_position( global_position )
	
	pass
