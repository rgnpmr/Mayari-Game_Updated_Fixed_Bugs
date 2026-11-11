extends Node

var cleared_objects : Dictionary = {}

func mark_cleared( object_id : String ) -> void:
	var scene_path : String = get_tree().current_scene.scene_file_path
	if not cleared_objects.has( scene_path ):
		cleared_objects[ scene_path ] = []
	if not cleared_objects[ scene_path ].has( object_id ):
		cleared_objects[ scene_path ].append( object_id )

func is_cleared( object_id : String ) -> bool:
	var scene_path : String = get_tree().current_scene.scene_file_path
	if not cleared_objects.has( scene_path ):
		return false
	return cleared_objects[ scene_path ].has( object_id )
