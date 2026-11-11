@tool
@icon( "res://npc/icons/npc.svg" )
class_name Enkanto extends CharacterBody2D
signal do_behavior_enabled
var state : String = "idle"
var do_behavior : bool = true
@export var npc_resource : NPCResource : set = _set_npc_resource
@onready var animation = get_node_or_null("AnimationPlayer")
@onready var sprite = get_node_or_null("Sprite2D") if get_node_or_null("Sprite2D") else get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	setup_npc()
	if Engine.is_editor_hint():
		return
	gather_interactables()
	update_animation()
	do_behavior_enabled.emit()
	pass

func _physics_process(_delta: float) -> void:
	move_and_slide()

func gather_interactables() -> void:
	for c in get_children():
		if c is DialogueInteraction:
			c.player_interacted.connect( _on_player_interacted )
			c.finished.connect( _on_interaction_finished )

func _on_player_interacted() -> void:
	state = "idle"
	velocity = Vector2.ZERO
	update_animation()
	do_behavior = false
	pass

func _on_interaction_finished() -> void:
	state = "idle"
	update_animation()
	do_behavior = true
	do_behavior_enabled.emit()
	pass

func update_animation() -> void:
	var anim_name : String = "idle_down"
	if animation:
		animation.play( anim_name )
	elif sprite is AnimatedSprite2D:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation( anim_name ):
			sprite.play( anim_name )
	pass

func setup_npc() -> void:
	if npc_resource and sprite is Sprite2D:
		sprite.texture = npc_resource.sprite
	pass

func _set_npc_resource( _npc : NPCResource ) -> void:
	npc_resource = _npc
	setup_npc()
