class_name GemSocket extends Node2D

@export var required_gem : ItemData
@export_group("Quest Tracking")
@export var quest_title : String = "Calming the Crater"
@export var quest_step_id : String = ""
@export_group("Engkanto Hint")
@export var engkanto_info : NPCResource
@export_multiline var hint_text : String = ""
@export_group("Messages")
@export var wrong_gem_message : String = "Hindi ito ang tamang perlas para dito."

@onready var interaction_area: Area2D = $InteractionGemConfirm
@onready var gem_display: Sprite2D = $Area2D/Gem_Sprite
@onready var gem_display_anim: AnimationPlayer = $Area2D/AnimationPlayer

var filled : bool = false
var busy : bool = false

func _ready() -> void:
	interaction_area.area_entered.connect( _on_area_enter )
	interaction_area.area_exited.connect( _on_area_exit )
	
	if gem_display:
		gem_display.visible = false
	
	# Coming back to this level: a gem placed earlier stays in its socket
	if LevelManager.is_gem_placed( _level_path(), required_gem, quest_step_id ):
		filled = true
		_show_gem_instantly()

func _on_area_enter( _a : Area2D ) -> void:
	if filled:
		return
	if not PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.connect( _try_show_prompt )

func _on_area_exit( _a : Area2D ) -> void:
	if PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.disconnect( _try_show_prompt )

func _try_show_prompt() -> void:
	if busy or filled:
		return
	busy = true
	_show_gem_hint()

func _show_gem_hint() -> void:
	var _hint_item := DialogueText.new()
	_hint_item.npc_info = engkanto_info
	
	if hint_text != "":
		_hint_item.text = hint_text
	elif required_gem:
		_hint_item.text = "Ito ay naghahanap ng " + required_gem.name + "."
	else:
		_hint_item.text = "Ito ay may hinihintay"
	
	if not DialogueSystem.finished.is_connected( _on_hint_finished ):
		DialogueSystem.finished.connect( _on_hint_finished, CONNECT_ONE_SHOT )
	
	var _items : Array[ DialogueItem ] = [ _hint_item ]
	DialogueSystem.show_dialogue( _items )

func _on_hint_finished() -> void:
	if filled:
		busy = false
		return
	
	if not ConfirmPromptUI.yes_pressed.is_connected( _on_confirmed ):
		ConfirmPromptUI.yes_pressed.connect( _on_confirmed, CONNECT_ONE_SHOT )
	if not ConfirmPromptUI.no_pressed.is_connected( _on_cancelled ):
		ConfirmPromptUI.no_pressed.connect( _on_cancelled, CONNECT_ONE_SHOT )
	ConfirmPromptUI.show_prompt( "Ilagay dito?" )

func _on_confirmed() -> void:
	if ConfirmPromptUI.no_pressed.is_connected( _on_cancelled ):
		ConfirmPromptUI.no_pressed.disconnect( _on_cancelled )
	
	if filled:
		busy = false
		return
	
	PauseMenu.item_selected_for_placement.connect( _on_item_selected, CONNECT_ONE_SHOT )
	PauseMenu.item_placement_cancelled.connect( _on_placement_cancelled, CONNECT_ONE_SHOT )
	PauseMenu.start_item_placement()

func _on_placement_cancelled() -> void:
	if PauseMenu.item_selected_for_placement.is_connected( _on_item_selected ):
		PauseMenu.item_selected_for_placement.disconnect( _on_item_selected )
	busy = false

func _on_item_selected( item : ItemData ) -> void:
	if PauseMenu.item_placement_cancelled.is_connected( _on_placement_cancelled ):
		PauseMenu.item_placement_cancelled.disconnect( _on_placement_cancelled )
	
	busy = false
	
	if item != required_gem:
		# A wrong gem: nothing is used up, the player is told
		if item != null:
			NotificationManager.add_notification_to_queue( "Mali", wrong_gem_message )
		return
	
	if not PlayerManager.INVENTORY_DATA.remove_item( required_gem, 1 ):
		return
	
	filled = true
	LevelManager.register_placed_gem( required_gem, quest_title, quest_step_id, _level_path() )
	
	if quest_title != "" and quest_step_id != "":
		QuestManager.update_quest( quest_title, quest_step_id )
	
	if gem_display:
		gem_display.visible = true
		if gem_display_anim and gem_display_anim.has_animation("show"):
			gem_display_anim.play("show")
	
	for effect in required_gem.effects:
		if effect is SpawnSceneEffect:
			effect.use_at( gem_display.global_position )

func _on_cancelled() -> void:
	if ConfirmPromptUI.yes_pressed.is_connected( _on_confirmed ):
		ConfirmPromptUI.yes_pressed.disconnect( _on_confirmed )
	busy = false

func _level_path() -> String:
	var root : Node = owner if owner != null else get_tree().current_scene
	return root.scene_file_path if root != null else ""

# Shows the placed gem at once, with no fade-in
func _show_gem_instantly() -> void:
	if gem_display == null:
		return
	gem_display.visible = true
	if gem_display_anim and gem_display_anim.has_animation( "show" ):
		gem_display_anim.play( "show" )
		gem_display_anim.seek( gem_display_anim.current_animation_length, true )
