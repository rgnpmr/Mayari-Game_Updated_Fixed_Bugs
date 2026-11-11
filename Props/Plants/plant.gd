class_name Plant extends Node2D
@export_group("Quest Tracking")
@export var quest_title : String = ""
@export var quest_step_id : String = ""

func _ready() -> void:
	$HitBox.damaged.connect( TakeDamage )
	pass

func TakeDamage( _hurt_box : HurtBox ) -> void:
	if quest_title != "" and quest_step_id != "":
		QuestManager.update_quest( quest_title, quest_step_id )
	queue_free()
	pass
