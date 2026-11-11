extends CanvasLayer

@onready var minimap_frame : PanelContainer = $MiniMapFrame
@onready var minimap_viewport : SubViewport = $MiniMapFrame/MiniMapContent/MarginContainer/MiniMapContainer/MiniMapViewport
@onready var minimap_camera : Camera2D = $MiniMapFrame/MiniMapContent/MarginContainer/MiniMapContainer/MiniMapViewport/MiniMapCamera
@onready var minimap_container : SubViewportContainer = $MiniMapFrame/MiniMapContent/MarginContainer/MiniMapContainer
@onready var markers_layer : Control = $MiniMapFrame/MiniMapContent/MarkersLayer

@export var zoom_amount : Vector2 = Vector2(0.4, 0.4)

const DOT_SIZE : float = 7.0
const MINIMAP_MASK : int = 2 
var marker_dots : Dictionary = {}
var player_dot : Panel
var game_started : bool = false
var collapsed : bool = true
var hidden_by_pause : bool = false
var hidden_by_story : bool = false
var bounds_min : Vector2 = Vector2.ZERO
var bounds_max : Vector2 = Vector2.ZERO
var bounds_initialized : bool = false

func _ready() -> void:
	minimap_viewport.world_2d = get_viewport().world_2d
	minimap_camera.zoom = zoom_amount
	minimap_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	minimap_viewport.canvas_cull_mask = MINIMAP_MASK
	LevelManager.level_loaded.connect( _tag_ground_for_minimap )

	minimap_frame.visible = false

	LevelManager.level_load_started.connect( _on_level_load_started )
	LevelManager.TileMapBoundsChanged.connect( _on_tilemap_bounds_changed )
	PauseMenu.shown.connect( _on_pause_shown )
	PauseMenu.hidden.connect( _on_pause_hidden )
	
	player_dot = _make_dot( Color( 1, 1, 1 ) )
	player_dot.z_index = 1

	_connect_to_story()

func _connect_to_story() -> void:
	var story_nodes := get_tree().get_nodes_in_group("story")
	if story_nodes.size() > 0:
		var story = story_nodes[0]
		if story.has_signal("story_finished"):
			story.story_finished.connect(_on_story_finished)

func show_minimap() -> void:
	game_started = true
	_update_frame_visibility()

func _on_story_finished() -> void:
	show_minimap()

func toggle_minimap() -> void:
	collapsed = not collapsed
	_update_frame_visibility()

func force_close() -> void:
	if not collapsed:
		collapsed = true
		_update_frame_visibility()

func force_open() -> void:
	if collapsed:
		collapsed = false
		_update_frame_visibility()

func hide_for_story() -> void:
	hidden_by_story = true
	_update_frame_visibility()

func show_after_story() -> void:
	hidden_by_story = false
	_update_frame_visibility()

func _on_pause_shown() -> void:
	hidden_by_pause = true
	_update_frame_visibility()

func _on_pause_hidden() -> void:
	hidden_by_pause = false
	_update_frame_visibility()

func _update_frame_visibility() -> void:
	minimap_frame.visible = game_started and not hidden_by_pause and not hidden_by_story and not collapsed
	if minimap_frame.visible:
		_tag_ground_for_minimap()
		_apply_auto_zoom()

func _on_level_load_started() -> void:
	bounds_initialized = false

func _on_tilemap_bounds_changed( bounds : Array[ Vector2 ] ) -> void:
	if bounds.size() < 2:
		return
	var top_left : Vector2 = bounds[0]
	var bottom_right : Vector2 = bounds[1]

	if not bounds_initialized:
		bounds_min = top_left
		bounds_max = bottom_right
		bounds_initialized = true
	else:
		bounds_min.x = min( bounds_min.x, top_left.x )
		bounds_min.y = min( bounds_min.y, top_left.y )
		bounds_max.x = max( bounds_max.x, bottom_right.x )
		bounds_max.y = max( bounds_max.y, bottom_right.y )

	minimap_camera.limit_left = int( bounds_min.x )
	minimap_camera.limit_top = int( bounds_min.y )
	minimap_camera.limit_right = int( bounds_max.x )
	minimap_camera.limit_bottom = int( bounds_max.y )
	
	_apply_auto_zoom()

func _update_markers() -> void:
	if not minimap_frame.visible:
		return
	
	var active_title : String = QuestView.get_selected_quest_title().to_lower()
	var center : Vector2 = minimap_container.global_position + minimap_container.size * 0.5
	var radius : float = min( minimap_container.size.x, minimap_container.size.y ) * 0.5 - DOT_SIZE
	var cam_center : Vector2 = minimap_camera.get_screen_center_position()
	var seen : Array = []
	
	for node in get_tree().get_nodes_in_group("minimap_marker"):
		var marker := node as MinimapMarker
		if marker == null:
			continue
		if not marker.always_visible:
			if active_title == "" or marker.quest_title.to_lower() != active_title:
				continue
		
		seen.append( marker )
		var dot : Panel = marker_dots.get( marker )
		if dot == null:
			dot = _make_dot( marker.marker_color )
			marker_dots[ marker ] = dot
		
		var dot_offset : Vector2 = ( marker.global_position - cam_center ) * minimap_camera.zoom
		if dot_offset.length() > radius:
			dot_offset = dot_offset.normalized() * radius
		dot.global_position = center + dot_offset - Vector2( DOT_SIZE, DOT_SIZE ) * 0.5
	
	for marker in marker_dots.keys():
		if not is_instance_valid( marker ) or not seen.has( marker ):
			marker_dots[ marker ].queue_free()
			marker_dots.erase( marker )

func _make_dot( color : Color ) -> Panel:
	var dot := Panel.new()
	dot.size = Vector2( DOT_SIZE, DOT_SIZE )
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all( int( DOT_SIZE / 2.0 ) )
	style.set_border_width_all( 1 )
	style.border_color = Color( 0, 0, 0, 0.8 )
	dot.add_theme_stylebox_override( "panel", style )
	
	markers_layer.add_child( dot )
	return dot

func _process(_delta: float) -> void:
	if not game_started:
		return
	if PlayerManager.player:
		minimap_camera.global_position = PlayerManager.player.global_position.round()
	_update_markers()
	_update_player_dot()

func _tag_ground_for_minimap() -> void:
	var layers : Array = get_tree().current_scene.find_children( "*", "TileMapLayer", true, false )
	for node in layers:
		var item := node as CanvasItem
		while item != null:
			item.visibility_layer |= MINIMAP_MASK
			item = item.get_parent() as CanvasItem

func _update_player_dot() -> void:
	if not minimap_frame.visible or not PlayerManager.player:
		return
	
	var center : Vector2 = minimap_container.global_position + minimap_container.size * 0.5
	var radius : float = min( minimap_container.size.x, minimap_container.size.y ) * 0.5 - DOT_SIZE
	var cam_center : Vector2 = minimap_camera.get_screen_center_position()
	
	var dot_offset : Vector2 = ( PlayerManager.player.global_position - cam_center ) * minimap_camera.zoom
	if dot_offset.length() > radius:
		dot_offset = dot_offset.normalized() * radius
	player_dot.global_position = center + dot_offset - Vector2( DOT_SIZE, DOT_SIZE ) * 0.5

func _apply_auto_zoom() -> void:
	var level_size : Vector2 = bounds_max - bounds_min
	if not bounds_initialized or level_size.x <= 0.0 or level_size.y <= 0.0:
		minimap_camera.zoom = zoom_amount
		return
	
	var view_size : Vector2 = minimap_container.size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		view_size = Vector2( minimap_viewport.size )
	
	# The smallest zoom that still keeps the view inside the level
	var fit_zoom : float = max( view_size.x / level_size.x, view_size.y / level_size.y )
	var z : float = max( zoom_amount.x, fit_zoom )
	minimap_camera.zoom = Vector2( z, z )
