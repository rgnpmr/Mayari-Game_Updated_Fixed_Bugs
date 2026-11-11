class_name Chicken extends CharacterBody2D

signal direction_changed( new_direction : Vector2 )

const DIR_4 = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]


@export var move_speed : float = 20.0
@export var idle_time_min : float = 1.5
@export var idle_time_max : float = 3.5
@export var walk_time_min : float = 1.0
@export var walk_time_max : float = 2.5

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var player : Player
var invulnerable : bool = false
var is_walking : bool = false

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D
@onready var behavior_timer : Timer = Timer.new()

func _ready() -> void:
	player = PlayerManager.player
	
	add_child( behavior_timer )
	behavior_timer.one_shot = true
	behavior_timer.timeout.connect( _on_behavior_timer_timeout )
	
	_start_idle()

func _physics_process( _delta ):
	if is_walking:
		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func _start_idle() -> void:
	is_walking = false
	direction = Vector2.ZERO
	update_animation( "idle" )
	behavior_timer.start( randf_range( idle_time_min, idle_time_max ) )

func _start_walk() -> void:
	is_walking = true
	var random_dir : Vector2 = DIR_4[ randi() % DIR_4.size() ]
	set_direction( random_dir )
	update_animation( "walk" )
	behavior_timer.start( randf_range( walk_time_min, walk_time_max ) )

func _on_behavior_timer_timeout() -> void:
	if is_walking:
		_start_idle()
	else:
		_start_walk()

func set_direction( _new_direction : Vector2 ) -> bool:
	direction = _new_direction
	if direction == Vector2.ZERO:
		return false
	
	var direction_id : int = int( round(
		( direction + cardinal_direction * 0.1 ).angle()
		/TAU * DIR_4.size()
	))
	var new_dir = DIR_4[ direction_id ]
	
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	direction_changed.emit( new_dir )
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func update_animation( state : String ) -> void:
	animation_player.play(state + "_" + anim_direction() )

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"
