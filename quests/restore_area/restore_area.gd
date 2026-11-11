class_name RestoreArea extends Area2D

@export var quest_title : String = ""
@export var reward_scene : PackedScene   # e.g. gem.tscn or a returning animal scene
@export var healthy_texture : Texture2D

var restored : bool = false

@onready var sprite : Sprite2D = $Sprite2D
@onready var animation_player : AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	area_entered.connect( _on_area_enter )
	area_exited.connect( _on_area_exit )
	pass

func _on_area_enter( _a : Area2D ) -> void:
	if restored:
		return
	if not PlayerManager.interact_pressed.is_connected( _restore ):
		PlayerManager.interact_pressed.connect( _restore )
	pass

func _on_area_exit( _a : Area2D ) -> void:
	if PlayerManager.interact_pressed.is_connected( _restore ):
		PlayerManager.interact_pressed.disconnect( _restore )
	pass

func _restore() -> void:
	if restored:
		return
	restored = true
	
	if PlayerManager.interact_pressed.is_connected( _restore ):
		PlayerManager.interact_pressed.disconnect( _restore )
	
	if animation_player and animation_player.has_animation("restore"):
		animation_player.play("restore")
	elif healthy_texture:
		sprite.texture = healthy_texture
	
	if reward_scene:
		var reward = reward_scene.instantiate()
		reward.global_position = global_position
		get_parent().add_child( reward )
	
	if quest_title != "":
		QuestManager.increment_quest_progress( quest_title, 1 )
	pass
