extends Node2D

## The plant scenes to place. A random one is picked for every plant.
@export var plant_scenes : Array[PackedScene] = []
@export var count : int = 40
## The area to fill, in the village's own units. Start with the whole map.
@export var area : Rect2 = Rect2( 0, 0, 1140, 640 )
## Areas to keep empty, such as the houses and the paths
@export var avoid_rects : Array[Rect2] = []
## Each plant gets a random size between these (the village itself is at 0.5)
@export var min_scale : float = 2.0
@export var max_scale : float = 2.6
@export var random_seed : int = 3


func _ready() -> void:
	y_sort_enabled = true   # plants lower on the screen draw in front
	if plant_scenes.is_empty():
		push_warning( "PlantScatter: add your plant scenes to Plant Scenes." )
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed

	var placed : int = 0
	var tries : int = 0
	while placed < count and tries < count * 30:
		tries += 1
		var pos := Vector2(
			rng.randf_range( area.position.x, area.end.x ),
			rng.randf_range( area.position.y, area.end.y ) )

		var blocked : bool = false
		for r in avoid_rects:
			if r.has_point( pos ):
				blocked = true
				break
		if blocked:
			continue

		var scene : PackedScene = plant_scenes[ rng.randi() % plant_scenes.size() ]
		var p := scene.instantiate() as Node2D
		var s : float = rng.randf_range( min_scale, max_scale )
		p.scale = Vector2( s, s )
		p.position = pos
		add_child( p )
		placed += 1
