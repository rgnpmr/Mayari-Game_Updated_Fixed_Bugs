class_name RuinHouse extends Node2D

@export_group("Quest Tracking")
@export var quest_title : String = ""
@export var quest_step_id : String = ""
@export_group("Repair Requirements")
@export var required_item : ItemData
@export var required_quantity : int = 5
@export_group("Visuals")
@export var repaired_texture : Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $Area2D
@onready var prompt: CanvasLayer = get_node_or_null("QuestRuinHouseRepair")

var unique_id : String = ""
var busy : bool = false
var repaired : bool = false

func _ready() -> void:
	unique_id = str( get_path() )
	if WorldStateManager.is_cleared( unique_id ):
		repaired = true
		_apply_repaired_state( false )
		return
	interaction_area.area_entered.connect( _on_area_enter )
	interaction_area.area_exited.connect( _on_area_exit )
	if prompt:
		prompt.yes_pressed.connect( _on_confirmed )
		prompt.no_pressed.connect( _on_cancelled )
	pass

func _on_area_enter( _a : Area2D ) -> void:
	if repaired:
		return
	if not PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.connect( _try_show_prompt )

func _on_area_exit( _a : Area2D ) -> void:
	if PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.disconnect( _try_show_prompt )

func _try_show_prompt() -> void:
	if busy or repaired or prompt == null:
		return
	busy = true
	prompt.show_prompt()

func _on_confirmed() -> void:
	if repaired:
		busy = false
		return
	
	if required_item == null:
		busy = false
		return
	
	if not PlayerManager.INVENTORY_DATA.remove_item( required_item, required_quantity ):
		NotificationManager.add_notification_to_queue( "Kulang " + required_item.name, "Kaipuhan " + str( required_quantity ) )
		busy = false
		return
	
	repaired = true
	await _apply_repaired_state( true )
	WorldStateManager.mark_cleared( unique_id )
	
	if quest_title != "" and quest_step_id != "":
		QuestManager.advance_step( quest_title, quest_step_id, 1 )
	
	busy = false

func _on_cancelled() -> void:
	busy = false

func _apply_repaired_state( play_effect : bool ) -> void:
	if PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.disconnect( _try_show_prompt )
	
	if not repaired_texture or not sprite:
		return
	
	var _original_scale : Vector2 = sprite.scale
	var _size_correction : Vector2 = Vector2.ONE
	if sprite.texture:
		var _old_size : Vector2 = sprite.texture.get_size()
		var _new_size : Vector2 = repaired_texture.get_size()
		if _new_size.x > 0 and _new_size.y > 0:
			_size_correction = _old_size / _new_size
	
	var _final_scale : Vector2 = _original_scale * _size_correction
	
	if not play_effect:
		sprite.texture = repaired_texture
		sprite.scale = _final_scale
		return
	
	var _tween := create_tween()
	_tween.tween_property( sprite, "scale", _original_scale * 1.15, 0.15 ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_OUT )
	_tween.tween_callback( func(): sprite.texture = repaired_texture )
	_tween.tween_property( sprite, "scale", _final_scale, 0.25 ).set_trans( Tween.TRANS_BACK ).set_ease( Tween.EASE_OUT )
	await _tween.finished
