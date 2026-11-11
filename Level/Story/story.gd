extends CanvasLayer

signal story_finished

var dialogue_items: Array[DialogueItem]
var dialogue_index: int = 0
var text_in_progress: bool = false
var text_length: int = 0
var text_speed: float = 0.03

@onready var content: RichTextLabel = $PanelContainer/RichTextLabel
@onready var name_label: Label = get_node_or_null("PanelContainer/NameLabel")
@onready var timer: Timer = $Timer
@onready var audio_stream_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")
@onready var story_lines: Node = $StoryLines

func _ready() -> void:
	add_to_group("story")
	QuestView.hide_hud_menu()
	timer.timeout.connect(_on_timer_timeout)
	_gather_story_lines()
	if dialogue_items.size() > 0:
		_show_line()
	else:
		_finish_story()

func _gather_story_lines() -> void:
	for c in story_lines.get_children():
		if c is DialogueItem:
			dialogue_items.append(c)

func _unhandled_input(event: InputEvent) -> void:
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

	if name_label:
		if line.npc_info:
			name_label.text = line.npc_info.npc_name
			name_label.visible = true
		else:
			name_label.text = ""
			name_label.visible = false

	content.visible_characters = 0
	text_length = content.get_total_character_count()
	text_in_progress = true
	_start_timer()

func _finish_story() -> void:
	QuestView.show_hud_menu()
	story_finished.emit()

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
