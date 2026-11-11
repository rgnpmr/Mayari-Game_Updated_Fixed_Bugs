class_name Trunk extends Node2D

@export_group("Quest Tracking")
@export var quest_title : String = ""
@export var quest_step_id : String = ""

@export_group("Loot")
@export var drop_item : ItemData
@export var drop_quantity : int = 1
@export var notification_format : String = "+{qty} {name}" 

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_area: Area2D = $Area2D
@onready var prompt: CanvasLayer = get_node_or_null("QuestRestoreInteraction")
var unique_id : String = ""
var busy : bool = false

func _ready() -> void:
	unique_id = str( get_path() )
	if WorldStateManager.is_cleared( unique_id ):
		queue_free()
		return
	if animation_player and animation_player.has_animation("glow"):
		animation_player.play("glow")
	interaction_area.area_entered.connect( _on_area_enter )
	interaction_area.area_exited.connect( _on_area_exit )
	if prompt:
		prompt.yes_pressed.connect( _on_confirmed )
		prompt.no_pressed.connect( _on_cancelled )

func _on_area_enter( _a : Area2D ) -> void:
	if not PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.connect( _try_show_prompt )

func _on_area_exit( _a : Area2D ) -> void:
	if PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.disconnect( _try_show_prompt )

func _try_show_prompt() -> void:
	if busy or prompt == null:
		return
	prompt.show_prompt()

func _on_confirmed() -> void:
	busy = true
	if not _give_drop():
		busy = false
		return
	if quest_title != "" and quest_step_id != "":
		QuestManager.advance_step( quest_title, quest_step_id, 1 )
	WorldStateManager.mark_cleared( unique_id )
	queue_free()

func _give_drop() -> bool:
	if drop_item == null:
		return true
	if PlayerManager.INVENTORY_DATA.add_item( drop_item, drop_quantity ):
		var msg : String = notification_format \
			.replace( "{qty}", str( drop_quantity ) ) \
			.replace( "{name}", drop_item.name )
		NotificationManager.add_notification_to_queue( "", msg )
		return true
	NotificationManager.add_notification_to_queue( "", "Puno na ang bag" )
	return false

func _on_cancelled() -> void:
	busy = false
