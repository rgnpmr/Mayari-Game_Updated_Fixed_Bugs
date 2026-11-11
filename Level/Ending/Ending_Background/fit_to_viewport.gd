extends Node2D
## Put this on the root node of a map you use as a background.
## It scales and moves the map so all of its tiles fill the screen.

## The size to fill. Leave it at 0, 0 to use the real game screen size.
@export var target_size : Vector2 = Vector2.ZERO
## On: fills the whole screen, and may crop a little of the edges.
## Off: the whole map is visible, and there may be bars at the sides.
@export var cover : bool = true


func _ready() -> void:
	fit()


func fit() -> void:
	if target_size == Vector2.ZERO:
		target_size = get_viewport_rect().size
	var bounds : Rect2 = _tile_bounds( self )
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		push_warning( "fit_to_viewport: no tiles found under " + str( name ) )
		return

	var ratio : Vector2 = target_size / bounds.size
	var k : float = maxf( ratio.x, ratio.y ) if cover else minf( ratio.x, ratio.y )
	scale = Vector2( k, k )

	# Centre the map on the screen
	position = ( target_size - bounds.size * k ) / 2.0 - bounds.position * k


# The area covered by every TileMapLayer under this node, in this node's own coordinates
func _tile_bounds( node : Node ) -> Rect2:
	var result := Rect2()
	var has_any : bool = false
	for c in node.get_children():
		var r := Rect2()
		var found : bool = false

		if c is TileMapLayer and c.tile_set != null:
			var used : Rect2i = c.get_used_rect()
			if used.size.x > 0 and used.size.y > 0:
				var ts := Vector2( c.tile_set.tile_size )
				r = Rect2( Vector2( used.position ) * ts + c.position, Vector2( used.size ) * ts )
				found = true

		if found:
			result = r if not has_any else result.merge( r )
			has_any = true

		# Layers grouped under another node
		if c.get_child_count() > 0:
			var inner : Rect2 = _tile_bounds( c )
			if inner.size.x > 0.0:
				if c is Node2D:
					inner.position += c.position
				result = inner if not has_any else result.merge( inner )
				has_any = true
	return result
