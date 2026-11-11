extends Node
## Makes the swaying trees in THIS scene sway differently, without changing the tree scene itself.
## Add it as a plain Node anywhere inside the scene that holds the trees
## (for example a child of the map root). It affects its parent's whole branch.
##
## Each tree gets its own copy of the sway material, so the original tree.tscn
## and every other scene that uses the tree stay exactly as they were.

@export var sway_speed : float = 1.6
@export var sway_strength : float = 14.0
## Gives every tree a different starting point, so they don't all sway in step
@export var randomize_offset : bool = true
## Only materials that use this shader are changed
@export var shader_file_name : String = "tree_sway.gdshader"


func _ready() -> void:
	var changed : int = 0
	for n in get_parent().find_children( "*", "CanvasItem", true, false ):
		var item := n as CanvasItem
		var mat := item.material as ShaderMaterial
		if mat == null or mat.shader == null:
			continue
		if not mat.shader.resource_path.ends_with( shader_file_name ):
			continue

		# A private copy for this tree only
		var own := mat.duplicate() as ShaderMaterial
		own.set_shader_parameter( "sway_speed", sway_speed )
		own.set_shader_parameter( "sway_strength", sway_strength )
		if randomize_offset:
			own.set_shader_parameter( "sway_offset", randf() * 6.28 )
		item.material = own
		changed += 1

	print( "SwayBoost: changed ", changed, " trees" )
