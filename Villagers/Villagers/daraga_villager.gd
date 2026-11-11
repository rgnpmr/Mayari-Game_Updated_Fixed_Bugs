extends Area2D

@export var speed: float = 50.0
@export var patrol_distance: float = 300.0
@export var wait_time: float = 2.0 # Time to stand still in seconds

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var start_x: float
var direction: int = 1 # 1 = Moving Right, -1 = Moving Left
var is_waiting: bool = false

func _ready() -> void:
	start_x = global_position.x
	animated_sprite.play("walking")

func _process(delta: float) -> void:
	# Stop movement processing while waiting
	if is_waiting:
		return

	# Move the Area2D manually using position
	position.x += direction * speed * delta

	# Calculate offset from the starting point
	var current_offset: float = global_position.x - start_x

	# Check distance thresholds
	if direction == 1 and current_offset >= patrol_distance:
		start_wait(-1)
	elif direction == -1 and current_offset <= 0:
		start_wait(1)

func start_wait(next_direction: int) -> void:
	is_waiting = true
	animated_sprite.play("stand_still")
	
	# Wait for the specified time without freezing the engine
	await get_tree().create_timer(wait_time).timeout
	
	# Turn around and resume walking
	direction = next_direction
	animated_sprite.flip_h = (direction == -1)
	animated_sprite.play("walking")
	is_waiting = false
