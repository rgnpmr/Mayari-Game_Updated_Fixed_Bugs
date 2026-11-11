extends CanvasLayer

signal fight_finished

@export var agama_info : NPCResource
@export var kasili_info : NPCResource
@export var voice_volume_db : float = -4.0
## How much the background music is lowered while this scene plays
@export var music_duck_db : float = -10.0

# Background
@onready var texture_rect: TextureRect = $TextureRect
@onready var texture_rect_2: TextureRect = $TextureRect2

# Characters
@onready var agama_character: Sprite2D = $Agama/AgamaCharacter
@onready var kasili_character: Sprite2D = $Kasili/CalmKasili

# Agama dialogue
@onready var agama : CanvasLayer = $Agama
@onready var agama_content : RichTextLabel = $Agama/PanelContainer/RichTextLabel
@onready var agama_name_label : Label = $Agama/NameLabel

# Kasili dialogue
@onready var kasili : CanvasLayer = $Kasili
@onready var kasili_content : RichTextLabel = $Kasili/PanelContainer/RichTextLabel
@onready var kasili_name_label : Label = $Kasili/NameLabel

# Dialogue system
@onready var story_lines : Node = $StoryLines
@onready var timer : Timer = $Timer

var dialogue_items : Array[DialogueItem] = []
var dialogue_index : int = 0

var text_in_progress : bool = false
var text_length : int = 0
var text_speed : float = 0.03

var current_content : RichTextLabel

var voice_player : AudioStreamPlayer
var music_ducked : bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# No clock on screen during the ending scenes
	ClockDisplay.hide_hud()

	timer.timeout.connect(_on_timer_timeout)

	# The voice player is created here, so it needs no node in the scene
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.volume_db = voice_volume_db
	voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child( voice_player )
	_duck_music()

	# Keep both background TextureRects visible
	texture_rect.visible = true
	texture_rect_2.visible = true

	# Hide both characters at the beginning
	agama_character.visible = false
	kasili_character.visible = false

	# Hide both dialogue boxes at the beginning
	agama.visible = false
	kasili.visible = false

	# Gather dialogue
	_gather_dialogue_lines()

	# Start dialogue
	if dialogue_items.size() > 0:
		_show_line()
	else:
		_finish_fight()


func _gather_dialogue_lines() -> void:
	dialogue_items.clear()

	for c in story_lines.get_children():
		if c is DialogueItem:
			dialogue_items.append(c)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_advance()


func _advance() -> void:

	# If text is still typing,
	# Space finishes the current dialogue.
	if text_in_progress:
		current_content.visible_characters = text_length
		timer.stop()
		text_in_progress = false
		return

	# Move to next dialogue
	dialogue_index += 1

	if dialogue_index < dialogue_items.size():
		_show_line()
	else:
		_finish_fight()


func _show_line() -> void:
	var line : DialogueItem = dialogue_items[dialogue_index]

	# Determine who is speaking
	var is_agama : bool = line.npc_info != null and line.npc_info.npc_name.to_lower() == "agama"

	# Name always comes from the line itself
	var speaker_name : String = ""
	if line.npc_info:
		speaker_name = line.npc_info.npc_name

	if is_agama:
		agama_character.visible = true
		agama.visible = true

		kasili_character.visible = false
		kasili.visible = false

		current_content = agama_content

		agama_name_label.text = speaker_name

	else:
		kasili_character.visible = true
		kasili.visible = true

		agama_character.visible = false
		agama.visible = false

		current_content = kasili_content

		kasili_name_label.text = speaker_name

	# Set dialogue text
	current_content.text = line.text
	current_content.visible_characters = 0

	# Play this line's voice clip (stops the previous one)
	_play_voice( line )

	# Get text length
	text_length = current_content.get_total_character_count()

	# Start typing
	text_in_progress = true
	_start_timer()


func _start_timer() -> void:
	timer.wait_time = text_speed
	timer.start()


func _on_timer_timeout() -> void:
	current_content.visible_characters += 1

	if current_content.visible_characters >= text_length:
		current_content.visible_characters = text_length
		text_in_progress = false
		timer.stop()
	else:
		_start_timer()


func _finish_fight() -> void:
	timer.stop()
	_stop_voice()
	_unduck_music()

	text_in_progress = false

	# Hide characters
	agama_character.visible = false
	kasili_character.visible = false

	# Hide dialogue boxes
	agama.visible = false
	kasili.visible = false

	# Background stays visible
	texture_rect.visible = true
	texture_rect_2.visible = true

	fight_finished.emit()


# --- Voice and music helpers ---

func _play_voice( line : DialogueItem ) -> void:
	_stop_voice()
	if line is DialogueText and line.voice != null and voice_player:
		voice_player.stream = line.voice
		voice_player.play()


func _stop_voice() -> void:
	if voice_player:
		voice_player.stop()


func _duck_music() -> void:
	var music := get_node_or_null("/root/MusicManager")
	if music and not music_ducked:
		music.duck( music_duck_db )
		music_ducked = true


func _unduck_music() -> void:
	var music := get_node_or_null("/root/MusicManager")
	if music and music_ducked:
		music.unduck()
		music_ducked = false
