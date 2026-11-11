@tool
class_name ItemPickup extends CharacterBody2D
@export var item_data : ItemData : set = _set_item_data
@export_group("Quest Tracking")
@export var quest_title : String = ""
@export var quest_step_id : String = ""
@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	_update_texture()
	if Engine.is_editor_hint():
		return
	
	# NEW: if this pickup was already collected, it does not come back
	if _is_placed_in_level() and WorldStateManager.is_cleared( _unique_id() ):
		queue_free()
		return
	
	area_2d.body_entered.connect( _on_body_entered )
	if animation_player and animation_player.has_animation("glow"):
		animation_player.play("glow")
	pass

# NEW: true for a pickup placed in a level in the editor.
# Items dropped while playing (from an enemy, for example) are created by
# code, have no owner, and are never remembered.
func _is_placed_in_level() -> bool:
	return owner != null

# NEW: the name this pickup is remembered by
func _unique_id() -> String:
	return str( get_path() )

func _physics_process(delta: float) -> void:
	var collision_info = move_and_collide( velocity * delta )
	if collision_info:
		velocity = velocity.bounce( collision_info.get_normal() )
	velocity -= velocity * delta * 4 

func _on_body_entered( b ) -> void:
	if b is Player:
		if item_data:
			if PlayerManager.INVENTORY_DATA.add_item( item_data ) == true:
				NotificationManager.add_notification_to_queue( "Item Picked Up", item_data.name )
				if quest_title != "":
					if quest_step_id != "":
						QuestManager.advance_step( quest_title, quest_step_id )
					else:
						QuestManager.increment_quest_progress( quest_title, 1 )
				item_picked_up()
	pass

func item_picked_up() -> void:
	# NEW: remember it, so it stays gone when you come back to this level
	if _is_placed_in_level():
		WorldStateManager.mark_cleared( _unique_id() )
	
	area_2d.body_entered.disconnect( _on_body_entered )
	audio_stream_player_2d.play()
	sprite_2d.visible = false
	if animation_player and animation_player.is_playing():
		animation_player.stop()
	await audio_stream_player_2d.finished
	queue_free()
	pass

func _set_item_data( value : ItemData ) -> void:
	item_data = value
	_update_texture()
	pass

func _update_texture() -> void:
	if item_data and sprite_2d:
		sprite_2d.texture = item_data.texture
	pass
