extends CanvasLayer

signal story_finished

@export var voice_volume_db: float = -4.0
@export var music_duck_db: float = -10.0

var dialogue_items: Array[DialogueItem]
var dialogue_index: int = 0
var text_in_progress: bool = false
var text_length: int = 0
var text_speed: float = 0.03

var voice_player: AudioStreamPlayer
var music_ducked: bool = false
var finished: bool = false # stops the story from finishing twice

@onready var content: RichTextLabel = $PanelContainer/RichTextLabel
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")
@onready var story_lines: Node = $StoryLines
@onready var skip_button: Button = $SkipButton
@onready var next_hint: Label = get_node_or_null("NextButton") # ADDED

func _ready() -> void:
	add_to_group("story")
	QuestView.hide_hud_menu()
	timer.timeout.connect(_on_timer_timeout)
	_set_continue_hint() # ADDED

	# skip button (no keyboard focus, so pressing Space can't trigger it)
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

# ADDED: shows the tap text on phones and the Space text on a laptop
func _set_continue_hint() -> void:
	if next_hint == null:
		return
	var on_phone := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if on_phone:
		next_hint.text = "Tap ang screen para magpatuloy"
	else:
		next_hint.text = "Pindutin ang \"space\" para magpatuloy"

func _exit_tree() -> void:
	# Safety net: if the scene is freed early, never leave the music ducked
	_unduck_music()

func _gather_story_lines() -> void:
	for c in story_lines.get_children():
		if c is DialogueItem:
			dialogue_items.append(c)

# a tap on the skip button works on a touch screen too
# a tap or a click on the skip button works, even if something covers the screen
func _input(event: InputEvent) -> void:
	if finished:
		return

	var pressed_at := Vector2.ZERO
	var is_press : bool = false

	if event is InputEventScreenTouch and event.pressed:
		pressed_at = event.position
		is_press = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed_at = event.position
		is_press = true

	if is_press and skip_button.visible and skip_button.get_global_rect().has_point( pressed_at ):
		_finish_story()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if finished:
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
	if finished: # only the first call does anything
		return
	finished = true
	timer.stop()
	text_in_progress = false
	skip_button.hide()
	voice_player.stop()
	_unduck_music()
	QuestView.show_hud_menu()
	story_finished.emit()

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
