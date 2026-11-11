extends Control

## The scene that opens after the logo
@export_file("*.tscn") var next_scene : String = "res://Level/Chapters/main_menu.tscn"

@export_group("Logo fade")
@export var fade_in_time : float = 1.0
## How long the logo stays after it appeared
@export var hold_time : float = 1.5
@export var fade_out_time : float = 0.8

@export_group("Loading text")
## Seconds between each dot in "Naglo-load..."
@export var dots_speed : float = 0.4

@onready var logo : TextureRect = $TextureRect
@onready var loading_label : Label = get_node_or_null("Label")
@export var max_dots : int = 3

var _base_text : String = ""
var _dots_time : float = 0.0
var _label_visible : bool = false


func _ready() -> void:
	ClockDisplay.hide_hud()
	logo.modulate.a = 0.0
	if loading_label:
		_base_text = loading_label.text.trim_suffix( "..." ).trim_suffix( "." )
		loading_label.modulate.a = 0.0
	
	# The main menu loads in the background while the logo shows
	ResourceLoader.load_threaded_request( next_scene )
	_run()


# The dots in "Naglo-load..." come and go
func _process( delta : float ) -> void:
	if loading_label == null or not _label_visible:
		return
	_dots_time += delta
	var dots : int = int( _dots_time / dots_speed ) % ( max_dots + 1 )
	loading_label.text = _base_text + ".".repeat( dots )


func _run() -> void:
	# 1. The logo fades in
	var intro := create_tween().set_parallel( true )
	intro.tween_property( logo, "modulate:a", 1.0, fade_in_time ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )
	if loading_label:
		intro.tween_property( loading_label, "modulate:a", 1.0, fade_in_time )
	await intro.finished
	_label_visible = true
	
	# 2. Hold, and wait until the main menu is ready
	await get_tree().create_timer( hold_time ).timeout
	while ResourceLoader.load_threaded_get_status( next_scene ) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	
	# 3. The logo fades out
	var outro := create_tween().set_parallel( true )
	outro.tween_property( logo, "modulate:a", 0.0, fade_out_time ).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN_OUT )
	if loading_label:
		outro.tween_property( loading_label, "modulate:a", 0.0, fade_out_time )
	await outro.finished
	
	var packed = ResourceLoader.load_threaded_get( next_scene )
	if packed is PackedScene:
		get_tree().change_scene_to_packed( packed )
	else:
		get_tree().change_scene_to_file( next_scene )
