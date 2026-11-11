class_name KeyPromptArea extends Area2D

@export var key_icon : Texture2D
@export var enabled : bool = true

@onready var sprite : Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	if key_icon:
		sprite.texture = key_icon
	sprite.visible = false
	area_entered.connect( _on_area_enter )
	area_exited.connect( _on_area_exit )
	pass

func _on_area_enter( _a : Area2D ) -> void:
	if enabled == false:
		return
	sprite.visible = true
	if animation_player and animation_player.has_animation("show"):
		animation_player.play("show")
	pass

func _on_area_exit( _a : Area2D ) -> void:
	if animation_player and animation_player.has_animation("hide"):
		animation_player.play("hide")
		await animation_player.animation_finished
	sprite.visible = false
	pass
