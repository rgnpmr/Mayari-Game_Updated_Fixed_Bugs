extends Node2D

signal story_finished

@export var voice_volume_db: float = -4.0
@export var music_duck_db: float = -10.0

var dialogue_items: Array[DialogueItem]
var dialogue_index: int = 0
var text_in_progress: bool = false
var text_length: int = 0
var text_speed: float = 0.03
var finished: bool = false # ADDED: stops the story from finishing twice

var voice_player: AudioStreamPlayer
var music_ducked: bool = false

@onready var content: RichTextLabel = $CanvasLayer/ColorRect/Content
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")
@onready var story_lines: Node = $CanvasLayer/StoryLines
@onready var skip_button: Button = get_node_or_null("CanvasLayer/SkipButton") # ADDED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("story")
	QuestView.hide_hud_menu()
	timer.timeout.connect(_on_timer_timeout)

	# ADDED: skip button (no keyboard focus, so pressing Space can't trigger it)
	if skip_button:
		skip_button.focus_mode = Control.FOCUS_NONE
		skip_button.pressed.connect(_finish_story)

	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.volume_db = voice_volume_db
	add_child(voice_player)

	_gather_story_lines()
	if dialogue_items.size() > 0:
		_duck_music()
		_show_line()
	else:
		_finish_story()

func _exit_tree() -> void:
	# Safety net: never leave the music ducked if the scene is freed early
	_unduck_music()

func _gather_story_lines() -> void:
	for c in story_lines.get_children():
		if c is DialogueItem:
			dialogue_items.append(c)

# ADDED: a click or a tap on the skip button works on a laptop and on a phone
func _input(event: InputEvent) -> void:
	if finished or skip_button == null or not skip_button.visible:
		return

	var pressed_at := Vector2.ZERO
	var is_press : bool = false

	if event is InputEventScreenTouch and event.pressed:
		pressed_at = event.position
		is_press = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed_at = event.position
		is_press = true

	if is_press and skip_button.get_global_rect().has_point(pressed_at):
		_finish_story()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if finished: # ADDED
		return
	if event.is_action_pressed("ui_accept"):
		if text_in_progress:
			content.visible_characters = text_length
			timer.stop()
			text_in_progress = false
			return

		dialogue_index += 1
		if dialogue_index < dialogue_items.size():
			_show_line()
		else:
			_finish_story()

func _show_line() -> void:
	var line: DialogueItem = dialogue_items[dialogue_index]
	content.text = line.text

	content.visible_characters = 0
	text_length = content.get_total_character_count()
	text_in_progress = true
	_play_voice(line)
	_start_timer()

func _play_voice(line: DialogueItem) -> void:
	voice_player.stop()
	if line is DialogueText and line.voice != null:
		voice_player.stream = line.voice
		voice_player.play()

func _finish_story() -> void:
	if finished: # ADDED: only the first call does anything
		return
	finished = true # ADDED
	timer.stop() # ADDED
	text_in_progress = false # ADDED
	if skip_button: # ADDED
		skip_button.hide()
	voice_player.stop()
	_unduck_music()
	QuestView.show_hud_menu()
	story_finished.emit()
	get_tree().paused = false
	queue_free()

func _duck_music() -> void:
	var music := get_node_or_null("/root/MusicManager")
	if music and not music_ducked:
		music.duck(music_duck_db)
		music_ducked = true

func _unduck_music() -> void:
	var music := get_node_or_null("/root/MusicManager")
	if music and music_ducked:
		music.unduck()
		music_ducked = false

func _start_timer() -> void:
	timer.wait_time = text_speed
	timer.start()

func _on_timer_timeout() -> void:
	content.visible_characters += 1
	if content.visible_characters <= text_length:
		if audio_stream_player:
			audio_stream_player.play()
		_start_timer()
	else:
		text_in_progress = false
