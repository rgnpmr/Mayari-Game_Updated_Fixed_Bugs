extends Node
@export var quest_title : String = "Restore the Forest"
@export var end_of_chapter_story : PackedScene
@export var next_chapter_scene : String = ""

func _ready() -> void:
	QuestManager.quest_updated.connect( _on_quest_updated )

func _on_quest_updated( q ) -> void:
	if q.title.to_lower() != quest_title.to_lower():
		return
	if not q.is_complete:
		return
	QuestManager.quest_updated.disconnect( _on_quest_updated )
	_play_story()

func _play_story() -> void:
	if end_of_chapter_story:
		var story = end_of_chapter_story.instantiate()
		get_tree().current_scene.add_child( story )
		await story.story_finished
	
	PlayerManager.shake_camera( 0.3 )
	
	if next_chapter_scene != "":
		LevelManager.load_new_level( next_chapter_scene, "", Vector2.ZERO )
