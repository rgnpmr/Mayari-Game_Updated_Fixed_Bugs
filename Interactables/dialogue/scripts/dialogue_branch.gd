@tool
@icon( "res://GUI/dialogue_system/icons/answer_bubble.svg" )
class_name DialogueBranch extends DialogueItem

signal selected

@export var text : String = "ok..."
@export var triggers_evacuation : bool = false
@export var launches_fight_scene : bool = false
@export var launches_talk_scene : bool = false

@export_group( "Requirement" )
## Leave empty for a branch with no requirement.
@export var required_quest_title : String = ""
## A quest step that must be completed before this branch works
## (same name as in the Quest resource).
@export var required_step_id : String = ""
## Shown as a notification when the player picks this branch too early.
@export var locked_message : String = "Need to collect the chicken first"
## Off: go back to the line before the choices (press next to see them again).
## On: end the conversation instead.
@export var close_conversation_when_locked : bool = false

var dialogue_items : Array[ DialogueItem]


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	for c in get_children():
		if c is DialogueItem:
			dialogue_items.append( c )

	pass


# True when this branch has no requirement, or the required quest step is done.
func is_unlocked() -> bool:
	if required_quest_title == "" or required_step_id == "":
		return true
	var quest_index : int = QuestManager.get_quest_index_by_title( required_quest_title )
	if quest_index == -1:
		return false  # quest not started yet
	var q = QuestManager.current_quests[ quest_index ]
	return q.completed_steps.has( required_step_id.strip_edges().to_lower() )
