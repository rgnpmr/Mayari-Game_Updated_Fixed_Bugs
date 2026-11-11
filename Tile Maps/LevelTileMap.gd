class_name LevelTileMap extends TileMapLayer

func _ready():
	LevelManager.ChangeTilemapBounds( GetTilemapBounds() )
	add_to_group( "ground" )
	pass

func GetTilemapBounds() -> Array[ Vector2 ]:
	var bounds : Array[ Vector2 ] = []
	bounds.append(
		Vector2( get_used_rect().position * rendering_quadrant_size )
	)
	bounds.append(
		Vector2( get_used_rect().end * rendering_quadrant_size )
	)
	return bounds

func set_wetness( value : float ) -> void:
	if material and material is ShaderMaterial:
		material.set_shader_parameter( "wetness", value )
