class_name RescueArea extends Area2D

@export_group("Quest Tracking")
@export var quest_title : String = "Rescue Remaining Wildlife"
@export var quest_step_id : String = "Fox"

@onready var prompt: CanvasLayer = get_node_or_null("RescueInteraction")
var rescued : bool = false
var busy : bool = false

func _ready() -> void:
	area_entered.connect( _on_area_enter )
	area_exited.connect( _on_area_exit )
	if prompt:
		prompt.yes_pressed.connect( _on_confirmed )
		prompt.no_pressed.connect( _on_cancelled )

func _on_area_enter( _a : Area2D ) -> void:
	if not PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.connect( _try_show_prompt )

func _on_area_exit( _a : Area2D ) -> void:
	if PlayerManager.interact_pressed.is_connected( _try_show_prompt ):
		PlayerManager.interact_pressed.disconnect( _try_show_prompt )

func _try_show_prompt() -> void:
	if busy or rescued or prompt == null:
		return
	prompt.show_prompt()

func _on_confirmed() -> void:
	if rescued:
		return
	busy = true
	rescued = true
	QuestManager.advance_step( quest_title, quest_step_id )
	get_parent().queue_free()

func _on_cancelled() -> void:
	busy = false
