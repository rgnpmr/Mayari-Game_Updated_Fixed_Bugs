extends CanvasLayer

signal flood_completed

@onready var water_overlay : ColorRect = $WaterOverlay
@onready var audio_player : AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")

@export var flood_duration : float = 4.0
@export var flood_sound : AudioStream

var shader_material : ShaderMaterial

func _ready() -> void:
	shader_material = water_overlay.material as ShaderMaterial
	visible = false

func start_flood() -> void:
	visible = true
	shader_material.set_shader_parameter( "water_level", 0.0 )

	if audio_player and flood_sound:
		audio_player.stream = flood_sound
		audio_player.play()

	var tween := create_tween()
	tween.tween_method(
		func(v): shader_material.set_shader_parameter( "water_level", v ),
		0.0, 1.0, flood_duration
	).set_trans( Tween.TRANS_SINE ).set_ease( Tween.EASE_IN )

	tween.finished.connect( _on_flood_finished )

func _on_flood_finished() -> void:
	flood_completed.emit()
	visible = false
