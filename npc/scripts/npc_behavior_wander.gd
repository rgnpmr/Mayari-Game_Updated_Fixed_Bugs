@tool
extends NPCBehavior

const DIRECTIONS = [ Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT ]

@export var wander_range : int = 2 : set = _set_wander_range
@export var wander_speed : float = 30.0
@export var wander_duration : float = 1.0
@export var idle_duration : float = 1.0

var original_position : Vector2

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	super()
	$CollisionShape2D.queue_free()
	original_position = npc.global_position


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if abs( global_position.distance_to( original_position ) ) > wander_range * 32:
		npc.velocity *= -1
		npc.direction *= -1
		npc.update_direction_name()
		if npc.direction_name == "side" and npc.direction.x < 0:
			npc.sprite.flip_h = true
		else: 
			npc.sprite.flip_h = false
		npc.update_animation()


func start()-> void:
	# IDLE PHASE
	if npc.do_behavior == false:
		return
	npc.state = "idle"
	npc.velocity = Vector2.ZERO
	npc.update_animation()
	await get_tree().create_timer( randf() * idle_duration + idle_duration * 0.5 ).timeout
	# WALK PHASE
	npc.state = "walk"
	var _dir : Vector2 = _get_wander_direction()
	npc.direction = _dir
	npc.velocity = wander_speed * _dir
	npc.update_direction_name()
	if npc.direction_name == "side" and npc.direction.x < 0:
		npc.sprite.flip_h = true
	else:
		npc.sprite.flip_h = false
	npc.update_animation()
	await get_tree().create_timer( randf() * wander_duration + wander_duration * 0.5 ).timeout
	# REPEAT
	if npc.do_behavior == false:
		return
	start()
	pass


func _get_wander_direction() -> Vector2:
	if global_position.distance_to( original_position ) > wander_range * 32 *0.6:
		var to_center : Vector2 = global_position.direction_to( original_position )
		if abs( to_center.x ) > abs( to_center.y ):
			return Vector2.RIGHT if to_center.x > 0 else Vector2.LEFT
		else:
			return Vector2.DOWN if to_center.y > 0 else Vector2.UP
	return DIRECTIONS[ randi_range(0,3) ]

func _set_wander_range( v : int ) -> void:
	wander_range = v
	$CollisionShape2D.shape.radius = v * 32.0
