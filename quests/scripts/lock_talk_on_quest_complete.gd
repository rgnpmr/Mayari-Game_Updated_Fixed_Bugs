class_name LockTalkOnQuestComplete extends Node

@export var quest_title : String = ""

var interactions : Array[DialogueInteraction] = []

func _ready() -> void:
	if quest_title == "":
		return
	
	for c in get_parent().get_children():
		if c is DialogueInteraction:
			interactions.append( c )
	if interactions.is_empty():
		return
	
	# Already finished earlier (for example, returning to this level)
	var index : int = QuestManager.get_quest_index_by_title( quest_title )
	if index != -1 and QuestManager.current_quests[ index ].is_complete:
		_lock()
		return
	
	QuestManager.quest_rewarded.connect( _on_quest_rewarded )

func _on_quest_rewarded( title : String ) -> void:
	if title.to_lower() != quest_title.to_lower():
		return
	# If the quest finished during a conversation, let that conversation end first
	if DialogueSystem.is_active:
		await DialogueSystem.finished
	_lock()

func _lock() -> void:
	for i in interactions:
		if is_instance_valid( i ):
			i.enabled = false
