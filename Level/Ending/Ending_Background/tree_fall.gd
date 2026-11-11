extends Node

## Leave empty to topple every tree. Or type a group name to topple only the trees in that group.
@export var only_group : String = ""
## The node that holds all the trees. Leave empty to use the node called "trees" in the same scene.
@export var trees_root : Node2D
## Your picture of a fallen tree
@export var fallen_texture : Texture2D
## Where the fallen picture's top-left corner goes, measured from the standing tree's dot.
## Tune this until the roots of the fallen tree sit where the standing trunk was.
@export var fallen_offset : Vector2 = Vector2( -10, -100 )
## On: some trees fall to the left (the picture is mirrored). Off: all fall to the right.
@export var both_directions : bool = true
## How many shakes until every tree has fallen
@export var shakes_to_all : int = 6
## Each tree waits a random time up to this, so they don't all fall at once
@export var max_delay : float = 0.8
## How far the standing tree leans before it drops, in degrees
@export var lean_degrees : float = 9.0
## Seconds the tree leans before it drops
@export var lean_seconds : float = 0.55
## The point the tree leans around, in the tree's own pixels (the bottom of the trunk).
@export var base_offset : Vector2 = Vector2.ZERO
## Make the fallen picture bigger or smaller (1 = same size as the standing tree)
@export var fallen_scale : float = 1.0
## On: all the trees are already fallen when the scene starts
@export var fall_on_start : bool = false

var _standing : Array[Node2D] = []
var _total : int = 0


func _ready() -> void:
	if trees_root == null:
		trees_root = get_parent().get_node_or_null( "trees" ) as Node2D
	if trees_root == null:
		push_warning( "TreeFall: set Trees Root in the Inspector." )
		return
	for c in trees_root.get_children():
		if c is Node2D:
			if only_group != "" and not c.is_in_group( only_group ):
				continue
			_standing.append( c )
	_total = _standing.size()

	if fall_on_start:
		call_deferred( "fall_all_now" )


# Call this once for every shake. A few more trees fall each time.
func topple_some() -> void:
	var n : int = ceili( float( _total ) / float( maxi( shakes_to_all, 1 ) ) )
	for i in n:
		if _standing.is_empty():
			return
		var t : Node2D = _standing.pop_at( randi() % _standing.size() )
		_topple( t )


# Makes every tree fall now
func fall_all() -> void:
	while not _standing.is_empty():
		_topple( _standing.pop_back() )


# Puts every tree on the ground at once, with no animation
func fall_all_now() -> void:
	while not _standing.is_empty():
		_topple( _standing.pop_back(), true )


func _topple( t : Node2D, instant : bool = false ) -> void:
	if not is_instance_valid( t ):
		return
	if fallen_texture == null:
		push_warning( "TreeFall: put your fallen tree picture into Fallen Texture." )
		return

	var left : bool = both_directions and randf() < 0.5
	var dir : float = -1.0 if left else 1.0
	var p0 : Vector2 = t.position
	var pivot : Vector2 = base_offset * t.scale

	# A holder at the tree's own spot, so the drawing order stays right
	var holder := Node2D.new()
	holder.position = p0
	holder.scale = t.scale * fallen_scale
	holder.visible = false
	t.get_parent().add_child( holder )

	# The fallen tree picture, inside the holder
	var fallen := Sprite2D.new()
	fallen.texture = fallen_texture
	fallen.centered = false
	fallen.flip_h = left
	fallen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var w : float = float( fallen_texture.get_width() )
	var off := fallen_offset
	if left:
		off.x = -( fallen_offset.x + w )
	fallen.position = off
	holder.add_child( fallen )

	# Already fallen: no leaning and no waiting, the tree is just on the ground
	if instant:
		t.visible = false
		holder.visible = true
		return

	var lean : float = deg_to_rad( lean_degrees ) * dir
	var tw := create_tween()
	tw.tween_interval( randf() * max_delay )
	# It leans slowly, and it gets faster, then it drops
	tw.tween_method( _set_angle.bind( t, p0, pivot ), 0.0, lean, lean_seconds ).set_trans( Tween.TRANS_QUAD ).set_ease( Tween.EASE_IN )
	tw.tween_callback( func():
		if is_instance_valid( t ):
			t.visible = false
		holder.visible = true )
	# A tiny bounce when it hits the ground
	tw.tween_property( fallen, "position:y", off.y - 3.0, 0.07 )
	tw.tween_property( fallen, "position:y", off.y, 0.07 )


# Leans the tree around the pivot point
func _set_angle( a : float, t : Node2D, p0 : Vector2, pivot : Vector2 ) -> void:
	if not is_instance_valid( t ):
		return
	t.rotation = a
	t.position = p0 + pivot - pivot.rotated( a )
