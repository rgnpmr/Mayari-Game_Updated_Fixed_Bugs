extends CanvasLayer

@onready var animation_player: AnimationPlayer = $Control/AnimationPlayer
@onready var control_node: Control = $Control

var is_black: bool = false

func _ready() -> void:
	control_node.set_anchors_and_offsets_preset( Control.PRESET_FULL_RECT )
	control_node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_out() -> bool:
	if is_black:
		return true
	control_node.mouse_filter = Control.MOUSE_FILTER_STOP
	animation_player.play("fade_out")
	await animation_player.animation_finished
	is_black = true
	return true

func fade_in() -> bool:
	animation_player.play("fade_in")
	await animation_player.animation_finished
	is_black = false
	control_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return true
