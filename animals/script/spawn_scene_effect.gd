class_name SpawnSceneEffect extends ItemEffect
@export_file("*.tscn") var scene_path : String

func use() -> void:
	_spawn_at( PlayerManager.player.global_position + ( PlayerManager.player.cardinal_direction * 16 ) )
	pass

func use_at( position : Vector2 ) -> void:
	_spawn_at( position )
	pass

func _spawn_at( position : Vector2 ) -> void:
	if scene_path == "":
		return
	
	var scene : PackedScene = load( scene_path )
	if scene == null:
		return
	
	var level : Node = PlayerManager.player.get_parent()
	var instance : Node2D = scene.instantiate()
	level.add_child( instance )
	instance.global_position = position
	pass
