extends CanvasLayer

signal branch_selected( index : int )

@onready var button_fight : Button = $PanelContainer/VBoxContainer/ButtonFight
@onready var button_talk : Button = $PanelContainer/VBoxContainer/ButtonTalk

func _ready() -> void:
	visible = false
	button_fight.pressed.connect( func(): _select( 0 ) )
	button_talk.pressed.connect( func(): _select( 1 ) )

func show_choices( _labels : Array[String] = [] ) -> void:
	visible = true
	button_fight.disabled = true
	button_talk.disabled = true

	await get_tree().create_timer(0.3).timeout
	button_fight.disabled = false
	button_talk.disabled = false
	button_fight.grab_focus()

func _select( index : int ) -> void:
	visible = false
	branch_selected.emit( index )
