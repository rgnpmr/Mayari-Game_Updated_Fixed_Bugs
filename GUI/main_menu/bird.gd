extends CharacterBody2D

@export var fly_speed : float = 40.0
@export var direction : Vector2 = Vector2.RIGHT
@export var wobble_amount : float = 6.0      # sideways drift in px/sec, 0 = perfectly straight
@export var wobble_speed : float = 2.0
@export var tilt_to_direction : bool = true
@export var max_lifetime : float = 40.0      # safety net so a bird can never live forever

@onready var sprite : Sprite2D = $Sprite2D
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var _time : float = 0.0
var _phase : float = 0.0

func _ready() -> void:
	animation_player.play("fly")
	direction = direction.normalized()
	sprite.flip_h = direction.x < 0
	if tilt_to_direction:
		sprite.rotation = direction.angle() + ( PI if sprite.flip_h else 0.0 )
	_phase = randf() * TAU
	
	# Free the bird once it has flown off screen
	var notifier := VisibleOnScreenNotifier2D.new()
	notifier.rect = Rect2( -8, -8, 16, 16 )
	add_child( notifier )
	notifier.screen_exited.connect( queue_free )
	
	get_tree().create_timer( max_lifetime ).timeout.connect( queue_free )

func _physics_process( delta : float ) -> void:
	_time += delta
	var sideways : Vector2 = direction.orthogonal() * sin( _time * wobble_speed + _phase ) * wobble_amount
	velocity = direction * fly_speed + sideways
	move_and_slide()
