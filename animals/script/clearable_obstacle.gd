class_name ClearableObstacle extends Area2D
@export_group("Quest Tracking")
@export var quest_title : String = ""
@export var quest_step_id : String = ""
var cleared : bool = false

func _ready() -> void:
	area_entered.connect( _on_area_enter )
	area_exited.connect( _on_area_exit )

func _on_area_enter( _a : Area2D ) -> void:
	if not PlayerManager.interact_pressed.is_connected( _clear ):
		PlayerManager.interact_pressed.connect( _clear )

func _on_area_exit( _a : Area2D ) -> void:
	if PlayerManager.interact_pressed.is_connected( _clear ):
		PlayerManager.interact_pressed.disconnect( _clear )

func _clear() -> void:
	if cleared:
		return
	cleared = true
	
	if quest_title != "" and quest_step_id != "":
		QuestManager.update_quest( quest_title, quest_step_id )
	
	get_parent().queue_free()
	pass
