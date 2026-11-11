extends Control
class_name DialogueScene

@export var lines : Array[DialogueLine] = []
@export var typewriter_speed : float = 0.03  # seconds per character

@onready var background : TextureRect = $Background
@onready var name_label : Label = $TextBox/NameLabel
@onready var dialogue_label : RichTextLabel = $TextBox/DialogueLabel
@onready var continue_prompt : Label = $TextBox/ContinuePrompt

var current_index : int = 0
var is_typing : bool = false
var typewriter_tween : Tween

signal dialogue_finished

func _ready() -> void:
	continue_prompt.visible = false
	if lines.size() > 0:
		_show_line( 0 )
	else:
		push_warning( "DialogueScene: no lines assigned" )

func _unhandled_input( event : InputEvent ) -> void:
	if event.is_action_pressed( "ui_accept" ):  # Space by default
		_on_advance()
		get_viewport().set_input_as_handled()

func _on_advance() -> void:
	if is_typing:
		_skip_typewriter()
		return

	current_index += 1
	if current_index >= lines.size():
		dialogue_finished.emit()
		return

	_show_line( current_index )

func _show_line( index : int ) -> void:
	var line : DialogueLine = lines[ index ]
	background.texture = line.background
	name_label.text = line.speaker_name
	continue_prompt.visible = false
	_start_typewriter( line.text )

func _start_typewriter( full_text : String ) -> void:
	is_typing = true
	dialogue_label.text = full_text
	dialogue_label.visible_ratio = 0.0

	if typewriter_tween:
		typewriter_tween.kill()

	var duration : float = full_text.length() * typewriter_speed
	typewriter_tween = create_tween()
	typewriter_tween.tween_property( dialogue_label, "visible_ratio", 1.0, duration )
	typewriter_tween.finished.connect( _on_typewriter_finished )

func _skip_typewriter() -> void:
	if typewriter_tween:
		typewriter_tween.kill()
	dialogue_label.visible_ratio = 1.0
	_on_typewriter_finished()

func _on_typewriter_finished() -> void:
	is_typing = false
	continue_prompt.visible = true
