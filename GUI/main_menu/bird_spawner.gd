class_name BirdSpawner extends Node

@export var bird_scene : PackedScene
@export var interval_min : float = 6.0
@export var interval_max : float = 14.0
@export var flock_size_min : int = 1
@export var flock_size_max : int = 5
@export var speed_min : float = 35.0
@export var speed_max : float = 60.0
@export var spread : float = 18.0              # how loosely the flock is grouped
@export var direction_variation : float = 8.0  # degrees of difference between birds in a flock
@export var margin : float = 40.0              # how far off screen the flock appears
@export var bird_z_index : int = 50            # draw above trees

var timer : Timer

func _ready() -> void:
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect( _on_timer_timeout )
	add_child( timer )
	_schedule_next()

func _schedule_next() -> void:
	timer.start( randf_range( interval_min, interval_max ) )

func _on_timer_timeout() -> void:
	_spawn_flock()
	_schedule_next()

func _get_view_rect() -> Rect2:
	var vp := get_viewport()
	var size : Vector2 = vp.get_visible_rect().size
	var cam := vp.get_camera_2d()
	if cam:
		var cam_size : Vector2 = size / cam.zoom
		return Rect2( cam.get_screen_center_position() - cam_size * 0.5, cam_size )
	return Rect2( Vector2.ZERO, size )

func _random_entry_point( rect : Rect2 ) -> Vector2:
	var p : Vector2
	match randi() % 4:
		0:
			p = Vector2( rect.position.x - margin, randf_range( rect.position.y, rect.end.y ) )
		1:
			p = Vector2( rect.end.x + margin, randf_range( rect.position.y, rect.end.y ) )
		2:
			p = Vector2( randf_range( rect.position.x, rect.end.x ), rect.position.y - margin )
		_:
			p = Vector2( randf_range( rect.position.x, rect.end.x ), rect.end.y + margin )
	return p

func _spawn_flock() -> void:
	if bird_scene == null:
		return
	
	var rect : Rect2 = _get_view_rect()
	var entry : Vector2 = _random_entry_point( rect )
	
	# Aim at a random spot inside the view so the flock crosses the screen
	var target : Vector2 = rect.position + Vector2(
		rect.size.x * randf_range( 0.25, 0.75 ),
		rect.size.y * randf_range( 0.25, 0.75 ) )
	var flock_dir : Vector2 = ( target - entry ).normalized()
	var flock_speed : float = randf_range( speed_min, speed_max )
	
	var count : int = randi_range( flock_size_min, flock_size_max )
	for i in count:
		var bird = bird_scene.instantiate()
		bird.direction = flock_dir.rotated( deg_to_rad( randf_range( -direction_variation, direction_variation ) ) )
		bird.fly_speed = flock_speed * randf_range( 0.9, 1.1 )
		bird.z_index = bird_z_index
		get_tree().current_scene.add_child( bird )
		
		var along : Vector2 = -flock_dir * randf_range( 0.0, spread * 2.0 )
		var across : Vector2 = flock_dir.orthogonal() * randf_range( -spread, spread )
		bird.global_position = entry + along + across
