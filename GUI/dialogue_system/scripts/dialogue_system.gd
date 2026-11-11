@tool
@icon( "res://GUI/dialogue_system/icons/star_bubble.svg" )
class_name DialogueSystemNode extends CanvasLayer

signal finished
#signal letter_added( letter : String )

@export var voice_volume_db : float = -4.0
@export var music_duck_db : float = -10.0
## If true, the typing blips are skipped on lines that have a voice clip
@export var mute_blips_when_voiced : bool = false

var is_active: bool = false
var text_in_progress : bool = false
var waiting_for_choice : bool = false
var ignore_input_this_frame : bool = false

# time of the last accepted "next", used to ignore a double trigger from one tap
var last_advance_msec : int = 0

var text_speed : float =0.02
var text_length : int = 0
var plain_text : String

var dialogue_items : Array[ DialogueItem ]
var dialogue_item_index : int = 0

var voice_player : AudioStreamPlayer
var music_ducked : bool = false
var current_line_has_voice : bool = false


@onready var dialogue_ui: Control = $DialogueUI
@onready var content: RichTextLabel = $DialogueUI/PanelContainer/RichTextLabel
@onready var name_label: Label = $DialogueUI/NameLabel
@onready var dialogue_progress_indicator: PanelContainer = $DialogueUI/DialogueProgressIndicator
@onready var dialogue_progress_indicator_label: Label = $DialogueUI/DialogueProgressIndicator/Label
@onready var timer: Timer = $DialogueUI/Timer
@onready var audio_stream_player: AudioStreamPlayer = $DialogueUI/AudioStreamPlayer
@onready var choice_options : VBoxContainer = $DialogueUI/VBoxContainer



func _ready() -> void:
	if Engine.is_editor_hint():
		if get_viewport() is Window:
			get_parent().remove_child( self )
			return
		return
	# Keep receiving input while the game is paused (dialogue pauses the tree)
	process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect( _on_timer_timeout )

	# Voice player lives here and keeps playing while the game is paused
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.volume_db = voice_volume_db
	voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child( voice_player )

	hide_dialogue()
	pass


func _unhandled_input( event: InputEvent) -> void:
	if is_active == false or ignore_input_this_frame:
		return
	if(
			event.is_action_pressed("interact") or
			event.is_action_pressed("ui_accept")
	):
		_advance()


# A tap anywhere on a touch screen advances the dialogue,
# and a tap on a choice button selects that choice
func _input( event: InputEvent ) -> void:
	if Engine.is_editor_hint():
		return
	if is_active == false or ignore_input_this_frame:
		return
	if not ( event is InputEventScreenTouch and event.pressed ):
		return

	if waiting_for_choice:
		for c in choice_options.get_children():
			if c is Button and c.get_global_rect().has_point( event.position ):
				c.pressed.emit()
				get_viewport().set_input_as_handled()
				return
		return

	_advance()
	get_viewport().set_input_as_handled()


func _advance() -> void:
	# ignore a second "next" that arrives within 200 ms of the first
	var now := Time.get_ticks_msec()
	if now - last_advance_msec < 200:
		return
	last_advance_msec = now

	if text_in_progress == true:
		content.visible_characters = text_length
		timer.stop()
		text_in_progress = false
		show_dialogue_button_indicator( true )
		return
	elif waiting_for_choice == true:
		return

	dialogue_item_index += 1
	if dialogue_item_index < dialogue_items.size():
		start_dialogue()
	else:
		hide_dialogue()
		finished.emit()


func show_dialogue( _items : Array[ DialogueItem ]) -> void:
	is_active = true
	ignore_input_this_frame = true
	dialogue_ui.visible = true
	dialogue_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	dialogue_items = _items
	dialogue_item_index = 0
	get_tree().paused = true
	_duck_music()
	_set_touch_controls_hidden( true )
	await get_tree().process_frame
	ignore_input_this_frame = false
	start_dialogue()
	pass


func hide_dialogue() -> void:
	is_active = false
	choice_options.visible = false
	dialogue_ui.visible = false
	dialogue_ui.process_mode = Node.PROCESS_MODE_DISABLED
	dialogue_item_index = 0
	get_tree().paused = false
	_stop_voice()
	_unduck_music()
	_set_touch_controls_hidden( false )
	pass


#Initialize UI variables for a new Dialog Interactions
func start_dialogue() -> void:
	waiting_for_choice = false
	show_dialogue_button_indicator( false )
	var _d : DialogueItem = dialogue_items[ dialogue_item_index ]

	if _d is DialogueText:
		set_dialog_text( _d as DialogueText )
	elif _d is DialogueChoice:
		_stop_voice()
		set_dialogue_choice( _d as DialogueChoice )
	pass


# Once set, start text typing timer
func set_dialog_text( _d : DialogueItem ) -> void:
	if _d is DialogueText:
		content.text = _d.text
		_play_voice( _d as DialogueText )
	name_label.text = _d.npc_info.npc_name if _d.npc_info else ""

	content.visible_characters = 0
	text_length = content.get_total_character_count()
	plain_text = content.get_parsed_text()
	text_in_progress = true
	start_timer()
	pass


# Set dialog choice UI based on parameters
func set_dialogue_choice( _d : DialogueChoice ) -> void:
	choice_options.visible = true
	waiting_for_choice = true
	for c in choice_options.get_children():
		c.queue_free()

	for i in _d.dialogue_branches.size():
		var _new_choice : Button = Button.new()
		_new_choice.text = _d.dialogue_branches[ i ].text
		_new_choice.icon = preload("res://Assets/icons/icons8-message-100.png")
		_new_choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_new_choice.expand_icon = false
		_new_choice.add_theme_constant_override("icon_max_width", 15)
		_new_choice.add_theme_constant_override("h_separation", 8)
		_new_choice.pressed.connect( _dialogue_choice_selected.bind( _d.dialogue_branches[i] ) )
		choice_options.add_child( _new_choice )
	await get_tree().process_frame
	choice_options.get_child( 0 ).grab_focus()
	pass


func _dialogue_choice_selected( _d : DialogueBranch) -> void:
	# guard: a tap can trigger both our tap handler and the emulated mouse click,
	# so only the first one counts
	if not waiting_for_choice:
		return
	waiting_for_choice = false

	# Branch has a quest requirement that isn't met yet: show a notification,
	# hide the choices and go back. Nothing else runs (no selected signal, no
	# follow-up dialogue), so quest steps can't be completed out of order.
	if not _d.is_unlocked():
		NotificationManager.add_notification_to_queue( _d.required_quest_title, _d.locked_message )
		choice_options.visible = false
		if _d.close_conversation_when_locked or dialogue_item_index == 0:
			hide_dialogue()
			finished.emit()
		else:
			# back to the line before the choices; pressing next shows them again
			dialogue_item_index -= 1
			start_dialogue()
		return

	choice_options.visible = false
	_d.selected.emit()
	show_dialogue( _d.dialogue_items )
	pass


func _on_timer_timeout() -> void:
	content.visible_characters += 1
	if content.visible_characters <= text_length:
		if not ( mute_blips_when_voiced and current_line_has_voice ):
			audio_stream_player.play()
		start_timer()
	else:
		show_dialogue_button_indicator( true )
		text_in_progress = false

	pass



func show_dialogue_button_indicator( _is_visible : bool ) -> void:
	dialogue_progress_indicator.visible = _is_visible
	if dialogue_item_index + 1 < dialogue_items.size():
		dialogue_progress_indicator_label.text = "Sunod"
	else:
		dialogue_progress_indicator_label.text = "Tapos"


func start_timer() -> void:
	timer.wait_time = text_speed
	# Manipulate wait_time
	timer.start()
	pass


func _play_voice( _d : DialogueText ) -> void:
	_stop_voice()
	if _d.voice != null and voice_player:
		current_line_has_voice = true
		voice_player.stream = _d.voice
		voice_player.play()

func _stop_voice() -> void:
	current_line_has_voice = false
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

func _set_touch_controls_hidden( value : bool ) -> void:
	var touch := get_node_or_null("/root/TouchControls")
	if touch:
		touch.suppressed = value
