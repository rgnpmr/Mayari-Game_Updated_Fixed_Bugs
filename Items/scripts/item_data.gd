class_name ItemData extends Resource

@export var name : String = ""
@export_multiline var description : String = ""
@export var texture : Texture2D

@export_category("Item Use Effects")
@export var effects : Array[ ItemEffect ]

@export_category("Quest Tracking")
@export var quest_title : String = ""
@export var quest_step_id : String = ""


func use() -> bool:
	if effects.size() == 0:
		return false
	
	for e in effects:
		if e:
			e.use()
	return true

func use_at( position : Vector2 ) -> bool:
	if effects.size() == 0:
		return false
	for e in effects:
		if e:
			e.use_at( position )
	return true
