@tool
@icon( "res://GUI/dialogue_system/icons/chat_bubbles.svg" )
class_name DialogueInteraction extends Area2D

signal player_interacted
signal finished
@export var enabled : bool = true
@export var show_icon_from_distance : bool = true   
@export var linked_quest : Quest
@export_group("Quest Tracking")
@export var quest_title : String = ""
@export var quest_step_id : String = ""
@export_group("")
# Quests that must be completed before this NPC will talk. Empty = no requirement.
@export_group("Requirements")
@export var required_quests : Array[String] = []
@export var locked_message : String = "Hindi pa ito ang tamang oras para makipag-usap."
# NEW 2: a step of a quest that must be done first (example: Hagad Tabang / Kanibag)
@export var required_step_quest : String = ""
@export var required_step : String = ""
# NEW 2: line shown when only the step is missing. Empty = uses Locked Message.
@export var step_locked_message : String = ""
@export_group("")
@export var story_scene_after : PackedScene
@export var next_chapter_scene : String = ""
var dialogue_items : Array[ DialogueItem ]
var _starting := false
var _locked_cooling := false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var conversation_intro: Node = get_node_or_null("ConversationIntro")
@onready var conversation_turn_in: Node = get_node_or_null("ConversationTurnIn")

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	area_entered.connect( _on_area_enter )
	area_exited.connect( _on_area_exit )
	
	if show_icon_from_distance and _has_available_dialogue():
		animation_player.play("show")
	else:
		animation_player.play("hide")
	pass

# True only when every required quest has been started and completed
func _quests_done() -> bool:
	for title in required_quests:
		var i : int = QuestManager.get_quest_index_by_title( title )
		if i == -1:
			return false
		if QuestManager.current_quests[ i ].is_complete == false:
			return false
	return true

# NEW 2: true when the required step of the quest is already done
func _step_done() -> bool:
	if required_step_quest == "" or required_step == "":
		return true
	var i : int = QuestManager.get_quest_index_by_title( required_step_quest )
	if i == -1:
		return false
	var q = QuestManager.current_quests[ i ]
	return q.completed_steps.has( required_step.to_lower() )

func _show_locked_message( text : String ) -> void:
	if _locked_cooling:
		return
	_locked_cooling = true
	NotificationManager.add_notification_to_queue( "Paalala", text )
	await get_tree().create_timer( 1.5 ).timeout
	_locked_cooling = false

func player_interact() -> void:
	if _starting or DialogueSystem.is_active:
		return
	if not _quests_done():
		_show_locked_message( locked_message )
		return
	# NEW 2: the step check
	if not _step_done():
		if step_locked_message != "":
			_show_locked_message( step_locked_message )
		else:
			_show_locked_message( locked_message )
		return
	_gather_active_dialogue()
	if dialogue_items.size() == 0:
		return

	_starting = true
	animation_player.play("hide")

	player_interacted.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	DialogueSystem.show_dialogue( dialogue_items )
	_starting = false

	if not DialogueSystem.finished.is_connected( _on_dialog_finished ):
		DialogueSystem.finished.connect( _on_dialog_finished )
	pass

func _has_available_dialogue() -> bool:
	var active_node : Node = conversation_intro
	
	if linked_quest:
		var quest_state : Dictionary = QuestManager.find_quest( linked_quest )
		if quest_state.title != "not found":
			active_node = conversation_turn_in
	
	if active_node == null:
		return false
	
	for c in active_node.get_children():
		if c is DialogueItem:
			return true
	return false

func _gather_active_dialogue() -> void:
	dialogue_items = []
	var active_node : Node = conversation_intro

	if linked_quest:
		var quest_state : Dictionary = QuestManager.find_quest( linked_quest )
		if quest_state.title != "not found":
			active_node = conversation_turn_in

	if active_node == null:
		return

	for c in active_node.get_children():
		if c is DialogueItem:
			dialogue_items.append( c )
	pass

func _on_area_enter( _a : Area2D ) -> void:
	if enabled == false:
		return
	if not show_icon_from_distance:
		animation_player.play("show")
	if not PlayerManager.interact_pressed.is_connected( player_interact ):
		PlayerManager.interact_pressed.connect( player_interact )
	pass

func _on_area_exit( _a : Area2D ) -> void:
	if not show_icon_from_distance:
		animation_player.play("hide")
	if PlayerManager.interact_pressed.is_connected( player_interact ):
		PlayerManager.interact_pressed.disconnect( player_interact )
	pass

func _on_dialog_finished() -> void:
	DialogueSystem.finished.disconnect( _on_dialog_finished )
	finished.emit()
	
	if quest_title != "" and quest_step_id != "":
		QuestManager.advance_step( quest_title, quest_step_id )
	
	if story_scene_after:
		var story = story_scene_after.instantiate()
		get_tree().current_scene.add_child( story )
		await story.story_finished
		
		PlayerManager.shake_camera( 0.3 )
		
		if next_chapter_scene != "":
			LevelManager.load_new_level( next_chapter_scene, "", Vector2.ZERO )
			return
	
	if show_icon_from_distance and _has_available_dialogue():
		animation_player.play("show")
	pass

func _get_configuration_warnings() -> PackedStringArray:
	if _check_for_dialogue_items() == false:
		return ["Requires at least one DialogueItem node inside ConversationIntro or ConversationTurnIn." ]
	else:
		return []
func _check_for_dialogue_items() -> bool:
	for group_name in ["ConversationIntro", "ConversationTurnIn"]:
		if has_node( group_name ):
			var group : Node = get_node( group_name )
			for c in group.get_children():
				if c is DialogueItem:
					return true
	return false
