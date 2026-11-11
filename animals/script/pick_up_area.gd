class_name PickUpArea extends Area2D
@export var chicken_item : ItemData
@export_group("Quest Tracking")
@export var quest_title : String = ""
@export var quest_step_id : String = ""
@onready var prompt: CanvasLayer = get_node_or_null("AnimalCollectInteraction")
var unique_id : String = ""
var collected : bool = false
var busy : bool = false

func _ready() -> void:
	unique_id = str( get_path() )
	if WorldStateManager.is_cleared( unique_id ):
		get_parent().queue_free()
		return
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
	if busy or collected or prompt == null:
		return
	prompt.show_prompt()

func _on_confirmed() -> void:
	if collected:
		return
	busy = true

	if PlayerManager.INVENTORY_DATA.add_item( chicken_item ):
		collected = true
		if quest_title != "":
			# Remember the item BEFORE advancing the step: the last animal can
			# complete the quest, and the quest needs to know every animal by then.
			QuestManager.track_collected_item( quest_title, chicken_item )
			if quest_step_id != "":
				QuestManager.advance_step( quest_title, quest_step_id )
			else:
				QuestManager.increment_quest_progress( quest_title, 1 )
		WorldStateManager.mark_cleared( unique_id )
		get_parent().queue_free()
	else:
		busy = false

func _on_cancelled() -> void:
	busy = false
