class_name Level extends Node2D
@export var auto_start_quests : Array[String] = []

func _ready() -> void:
	self.y_sort_enabled = true
	PlayerManager.set_as_parent( self )
	
	if LevelManager.target_transition == "" and has_node("PlayerSpawn"):
		PlayerManager.set_player_position( $PlayerSpawn.global_position )
	
	LevelManager.level_load_started.connect( _free_level )
	
	for title in auto_start_quests:
		if QuestManager.get_quest_index_by_title( title ) == -1:
			QuestManager.update_quest( title )
	
	MiniMapUI.show_minimap()
	_setup_crater_challenge_if_present()
	_setup_storm_if_present()
	pass

func _setup_crater_challenge_if_present() -> void:
	if has_node("CraterChallenge") and has_node("CraterTimerUI"):
		var crater_challenge : Node = $CraterChallenge
		var crater_timer_ui : CanvasLayer = $CraterTimerUI
		crater_timer_ui.connect_to_challenge( crater_challenge )

func _setup_storm_if_present() -> void:
	if has_node("StormEffect"):
		var storm : CanvasLayer = $StormEffect
		storm.start_storm()

func _free_level() -> void:
	PlayerManager.unparent_player( self )
	queue_free()
