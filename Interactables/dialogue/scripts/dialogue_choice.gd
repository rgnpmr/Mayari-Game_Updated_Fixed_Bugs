@tool
@icon( "res://GUI/dialogue_system/icons/question_bubble.svg" )
class_name DialogueChoice extends DialogueItem

var dialogue_branches : Array[ DialogueBranch ]

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	for c in get_children():
		if c is DialogueBranch:
			dialogue_branches.append( c )


func _get_configuration_warnings() -> PackedStringArray:
	if _check_for_dialogue_items() == false:
		return ["Requires at least one DialogueItem node." ]
	else:
		return []


func _check_for_dialogue_items() -> bool:
	var _count : int = 0
	for c in get_children():
		if c is DialogueBranch:
			_count += 1
			if _count > 1:
				return true
	return false
