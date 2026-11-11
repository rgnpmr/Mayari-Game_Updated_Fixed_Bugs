extends Area2D

@export var speed: float = 30.0
@export var patrol_distance: float = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var start_x: float
var direction: int = 1 # 1 = Moving Right, -1 = Moving Left

func _ready() -> void:
	start_x = global_position.x

func _process(delta: float) -> void:
	# Move the Area2D manually using position
	position.x += direction * speed * delta

	# Calculate offset from the starting point
	var current_offset: float = global_position.x - start_x

	# Check distance thresholds and flip direction
	if direction == 1 and current_offset >= patrol_distance:
		direction = -1
		animated_sprite.flip_h = true
	elif direction == -1 and current_offset <= 0:
		direction = 1
		animated_sprite.flip_h = false
