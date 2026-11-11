class_name RestArea extends Area2D

@export var enabled : bool = true
@export var lock_after_use : bool = false
@export var auto_start_quests : Array[String] = []
@export var completes_quest : String = ""
@export var end_of_chapter_story : PackedScene   
@export var next_chapter_scene : String = ""     

# NEW: quests that must be completed before the player can rest here.
# Leave empty on rest areas that have no requirement.
@export var required_quests : Array[String] = []
# NEW: shown when the player presses interact too early.
@export var locked_message : String = "Hindi pa ako pwedeng magpahinga. May kailangan pa akong tapusin."

var narration_items : Array[ DialogueItem ]

@onready var narration_node : Node = get_node_or_null("Narration")
# NEW: optional. Add a Node named "LockedNarration" with DialogueText children
# if you want the locked line as a dialogue. If it is missing, a notification is used.
@onready var locked_node : Node = get_node_or_null("LockedNarration")
@onready var rest_prompt : CanvasLayer = $RestPromptUI
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var player_in_range : bool = false
var busy : bool = false
var unique_id : String = ""

func _ready() -> void:
	unique_id = str( get_path() )
	if lock_after_use and WorldStateManager.is_cleared( unique_id ):
		enabled = false
	
	area_entered.connect( _on_area_enter )
	area_exited.connect( _on_area_exit )
	rest_prompt.rest_pressed.connect( _on_rest_confirmed )
	rest_prompt.cancel_pressed.connect( _on_rest_cancelled )
	animation_player.play("hide")
	pass

func _on_area_enter( _a : Area2D ) -> void:
	if enabled == false:
		return
	player_in_range = true
	animation_player.play("show")
	if not PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.connect( _try_show_prompt )
	pass

func _on_area_exit( _a : Area2D ) -> void:
	player_in_range = false
	animation_player.play("hide")
	if PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.disconnect( _try_show_prompt )
	pass

# NEW: true only when every required quest has been started and completed
func _requirements_met() -> bool:
	for title in required_quests:
		var i : int = QuestManager.get_quest_index_by_title( title )
		if i == -1:
			return false
		if QuestManager.current_quests[ i ].is_complete == false:
			return false
	return true

# NEW: the "not yet" line
func _show_locked_message() -> void:
	busy = true
	var items : Array[ DialogueItem ] = []
	if locked_node != null:
		for c in locked_node.get_children():
			if c is DialogueItem:
				items.append( c )
	
	if items.size() > 0:
		DialogueSystem.show_dialogue( items )
		DialogueSystem.finished.connect( _on_locked_finished, CONNECT_ONE_SHOT )
	else:
		NotificationManager.add_notification_to_queue( "Pahingalo", locked_message )
		await get_tree().create_timer( 1.0 ).timeout
		busy = false
	pass

func _on_locked_finished() -> void:
	busy = false
	pass

func _try_show_prompt() -> void:
	if busy or not enabled:
		return
	# NEW: block resting until the required quests are done
	if not _requirements_met():
		_show_locked_message()
		return
	rest_prompt.show_prompt()
	pass

func _on_rest_confirmed() -> void:
	busy = true
	
	if completes_quest != "":
		QuestManager.update_quest( completes_quest, "", true )
	
	_gather_narration()
	
	if narration_items.size() > 0:
		DialogueSystem.show_dialogue( narration_items )
		if not DialogueSystem.finished.is_connected( _on_narration_finished ):
			DialogueSystem.finished.connect( _on_narration_finished )
	else:
		_wake_up()
	pass

func _on_rest_cancelled() -> void:
	pass

func _gather_narration() -> void:
	narration_items = []
	if narration_node == null:
		return
	for c in narration_node.get_children():
		if c is DialogueItem:
			narration_items.append( c )
	pass

func _on_narration_finished() -> void:
	DialogueSystem.finished.disconnect( _on_narration_finished )
	_wake_up()
	pass

func _wake_up() -> void:
	await SceneTransition.fade_out()
	_lock_rest_area()
	
	if end_of_chapter_story and next_chapter_scene != "":
		var story = end_of_chapter_story.instantiate()
		get_tree().current_scene.add_child( story )
		await story.story_finished
		# LevelManager handles the fade and the scene change itself
		LevelManager.load_new_level( next_chapter_scene, "", Vector2.ZERO )
		return
	
	TimeManager.skip_to_morning()
	_start_auto_quests()
	
	await SceneTransition.fade_in()
	
	PlayerManager.shake_camera( 0.3 )
	
	busy = false
	pass

func _lock_rest_area() -> void:
	if not lock_after_use:
		return
	enabled = false
	WorldStateManager.mark_cleared( unique_id )
	if PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.disconnect( _try_show_prompt )
	animation_player.play( "hide" )

func _start_auto_quests() -> void:
	for title in auto_start_quests:
		if QuestManager.get_quest_index_by_title( title ) == -1:
			QuestManager.update_quest( title )
	pass
