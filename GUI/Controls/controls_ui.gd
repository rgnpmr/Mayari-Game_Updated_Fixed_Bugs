extends CanvasLayer

signal closed

@export var fade_time : float = 0.6

@onready var root_control : Control = $Control

var is_closing : bool = false

func _ready() -> void:
	root_control.modulate.a = 0.0
	process_mode = Node.PROCESS_MODE_ALWAYS
	# This panel only shows hints. It must never catch mouse clicks, or it sits on
	# top of the HUD and the Controls button can't be clicked a second time.
	_ignore_mouse( root_control )
	_play()
	pass

func _ignore_mouse( node : Node ) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		_ignore_mouse( c )

func _play() -> void:
	var tween := create_tween()
	tween.tween_property( root_control, "modulate:a", 1.0, fade_time )
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func close() -> void:
	# Pressing close twice (key and button) must not start two fades
	if is_closing:
		return
	is_closing = true
	var tween := create_tween()
	tween.tween_property( root_control, "modulate:a", 0.0, fade_time )
	tween.finished.connect( _on_closed )

func _on_closed() -> void:
	closed.emit()
	queue_free()
