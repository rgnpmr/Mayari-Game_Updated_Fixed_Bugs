class_name Fox extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Play the sleeping animation only
	animation_player.play("sleep")

func _physics_process(_delta: float) -> void:
	# Keep the dog completely still
	velocity = Vector2.ZERO
