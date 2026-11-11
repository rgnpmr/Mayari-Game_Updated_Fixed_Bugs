extends Node

@export var quest_title : String = "Rescue Displaced Animals"
@export var next_scene : String = ""

func _ready() -> void:
	QuestManager.quest_updated.connect( _on_quest_updated )
	pass

func _on_quest_updated( q ) -> void:
	if quest_title != "" and q.title.to_lower() == quest_title.to_lower() and q.is_complete:
		_go_to_next_scene()
	pass

func _go_to_next_scene() -> void:
	await SceneTransition.fade_out()
	LevelManager.load_new_level( next_scene, "", Vector2.ZERO )
	pass
