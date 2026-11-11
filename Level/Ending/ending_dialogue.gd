extends CanvasLayer

signal story_finished

@export var calm_ending_scene : PackedScene = preload("res://Level/Ending/ending_calm.tscn")
@export var catastrophe_ending_scene : PackedScene = preload("res://Level/Ending/ending_catastrophe.tscn")
@export var fight_scene : PackedScene
@export var talk_scene : PackedScene
@export var voice_volume_db : float = -4.0
## How much the music and ambience are lowered while the story plays (more negative = quieter)
@export var music_duck_db : float = -22.0
## The audio buses that are lowered while the story plays
@export var duck_buses : Array[String] = ["Music", "Ambience"]
@export var duck_fade_in : float = 0.4
@export var duck_fade_out : float = 1.0

var dialogue_items: Array[DialogueItem]
var dialogue_index: int = 0
var text_in_progress: bool = false
var text_length: int = 0
var text_speed: float = 0.03
var awaiting_choice: bool = false
var voice_player: AudioStreamPlayer
var music_ducked: bool = false
var _bus_base_db : Dictionary = {}
var gems_revealed : bool = false

@onready var content: RichTextLabel = $PanelContainer/RichTextLabel
@onready var name_label: Label = get_node_or_null("PanelContainer/NameLabel")
@onready var timer: Timer = $Timer
@onready var story_lines: Node = $StoryLines
@onready var text_panel: Control = $PanelContainer
@onready var next_hint: Label = get_node_or_null("NextButton")  # the "continue" label

func _ready() -> void:
	story_finished.connect( _on_story_finished )
	timer.timeout.connect(_on_timer_timeout)
	_set_continue_hint()

	# The voice player is created here, so it needs no node in the scene
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.volume_db = voice_volume_db
	voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child( voice_player )
	_duck_music()

	_gather_story_lines()
	if dialogue_items.size() > 0:
		_show_line()
	else:
		story_finished.emit()

# Shows the tap text on phones and the Space text on a laptop
func _set_continue_hint() -> void:
	if next_hint == null:
		return
	var on_phone := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if on_phone:
		next_hint.text = "Tap ang screen para magpatuloy"
	else:
		next_hint.text = "Pindutin ang \"space\" para magpatuloy"

func _gather_story_lines() -> void:
	for c in story_lines.get_children():
		if c is DialogueItem:
			dialogue_items.append(c)

func _unhandled_input(event: InputEvent) -> void:
	if awaiting_choice:
		return

	# A tap on the screen (phone) or Space / Enter (laptop) goes on
	if event is InputEventScreenTouch and event.pressed:
		_advance()
	elif event.is_action_pressed("ui_accept"):
		_advance()

# Finish the typing, or go to the next line
func _advance() -> void:
	if text_in_progress:
		content.visible_characters = text_length
		timer.stop()
		text_in_progress = false
		return

	dialogue_index += 1
	if dialogue_index < dialogue_items.size():
		_show_line()
	else:
		story_finished.emit()

func _show_line() -> void:
	var line: DialogueItem = dialogue_items[dialogue_index]

	if line is DialogueChoice:
		_show_choice( line )
		return

	content.text = line.text
	_play_voice( line )
	# Reveal the gems when a line has "Show Gems" turned on
	if line is DialogueText and line.show_gems and not gems_revealed:
		gems_revealed = true
		var gems := get_tree().get_nodes_in_group( "story_gems" )
		for i in gems.size():
			gems[i].reveal( i * 0.6 )

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

# Shows or hides the text box and the "continue" label together
func _set_text_visible( shown : bool ) -> void:
	text_panel.visible = shown
	if next_hint:
		next_hint.visible = shown

func _show_choice( choice : DialogueChoice ) -> void:
	awaiting_choice = true
	add_to_group( "choosing" )   # NEW: tells the touch controls to ignore taps
	_stop_voice()

	# Only the Fight / Talk buttons stay on screen, no text box behind them
	_set_text_visible( false )

	var labels : Array[String] = []
	for branch in choice.dialogue_branches:
		labels.append( branch.text )

	if not ChoicePromptUI.branch_selected.is_connected( _on_branch_selected ):
		ChoicePromptUI.branch_selected.connect( _on_branch_selected, CONNECT_ONE_SHOT )
	ChoicePromptUI.show_choices( labels )


func _on_branch_selected( branch_index : int ) -> void:
	awaiting_choice = false
	remove_from_group( "choosing" )

	var choice : DialogueChoice = dialogue_items[dialogue_index]
	var branch : DialogueBranch = choice.dialogue_branches[branch_index]

	if branch.triggers_evacuation:
		StoryFlags.village_damage_level = "high"
	else:
		StoryFlags.village_damage_level = "normal"

	if branch.launches_fight_scene:
		_launch_separate_scene( fight_scene )
		return

	if branch.launches_talk_scene:
		_launch_separate_scene( talk_scene )
		return

	# The story continues with this branch's lines, so bring the text box back
	_set_text_visible( true )

	for i in branch.dialogue_items.size():
		dialogue_items.insert( dialogue_index + 1 + i, branch.dialogue_items[i] )

	dialogue_index += 1
	_show_line()

func _launch_separate_scene( scene : PackedScene ) -> void:
	if scene == null:
		push_warning("No scene assigned for this branch!")
		story_finished.emit()
		return

	_stop_voice()
	_unduck_music()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

	var _instance = scene.instantiate()
	get_tree().current_scene.add_child( _instance )
	await _instance.fight_finished
	_instance.queue_free()

	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	story_finished.emit()

func _start_timer() -> void:
	timer.wait_time = text_speed
	timer.start()

func _on_timer_timeout() -> void:
	content.visible_characters += 1
	if content.visible_characters <= text_length:
		_start_timer()
	else:
		text_in_progress = false

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
	if music_ducked:
		return
	music_ducked = true
	_fade_buses( false, duck_fade_in )

func _unduck_music() -> void:
	if not music_ducked:
		return
	music_ducked = false
	_fade_buses( true, duck_fade_out )

# Lowers or restores the volume of the buses. The tween belongs to the game,
# not to this scene, so it still finishes when the scene changes.
func _fade_buses( restore : bool, time : float ) -> void:
	var tw := get_tree().create_tween()
	tw.set_parallel( true )
	for bus_name in duck_buses:
		var idx : int = AudioServer.get_bus_index( bus_name )
		if idx < 0:
			continue
		if not _bus_base_db.has( bus_name ):
			_bus_base_db[ bus_name ] = AudioServer.get_bus_volume_db( idx )
		var base : float = _bus_base_db[ bus_name ]
		var target : float = base if restore else base + music_duck_db
		tw.tween_method(
			func( v : float ): AudioServer.set_bus_volume_db( idx, v ),
			AudioServer.get_bus_volume_db( idx ),
			target,
			time
		)

# Safety net: if the scene is freed early, the buses go back to normal at once
func _exit_tree() -> void:
	if music_ducked:
		music_ducked = false
		for bus_name in _bus_base_db:
			var idx : int = AudioServer.get_bus_index( bus_name )
			if idx >= 0:
				AudioServer.set_bus_volume_db( idx, _bus_base_db[ bus_name ] )

func _on_story_finished() -> void:
	_stop_voice()
	_unduck_music()
	var next_scene : PackedScene
	if StoryFlags.village_damage_level == "high":
		next_scene = catastrophe_ending_scene
	else:
		next_scene = calm_ending_scene

	if next_scene:
		get_tree().change_scene_to_packed( next_scene )
	else:
		push_warning("No ending scene assigned for village_damage_level: " + StoryFlags.village_damage_level)
