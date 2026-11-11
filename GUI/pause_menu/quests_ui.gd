class_name QuestsUI extends Control
const QUEST_ITEM : PackedScene = preload("res://GUI/pause_menu/quests/quest_item.tscn")
const QUEST_STEP_ITEM : PackedScene = preload("res://GUI/pause_menu/quests/quest_step_item.tscn")
@onready var quest_item_container: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer
@onready var details_container: VBoxContainer = $ScrollContainer2/VBoxContainer
@onready var title_label: Label = $ScrollContainer2/VBoxContainer/TitleLabel
@onready var description_label: Label = $ScrollContainer2/VBoxContainer/DescriptionLabel
@onready var icon_rect: TextureRect = $ScrollContainer2/VBoxContainer/IconRect

func _ready() -> void:
	clear_quest_details()
	visibility_changed.connect( _on_visible_changed )
	pass

func _on_visible_changed() -> void:
	for i in quest_item_container.get_children():
		i.queue_free()
	
	clear_quest_details()
	
	if visible == true:
		QuestManager.sort_quests()
		for q in QuestManager.current_quests:
			var quest_data : Quest = QuestManager.find_quest_by_title( q.title )
			if quest_data == null:
				continue
			var new_q_item : QuestItem = QUEST_ITEM.instantiate()
			quest_item_container.add_child( new_q_item )
			new_q_item.initialize( quest_data, q )
			new_q_item.focus_entered.connect( update_quest_details.bind( new_q_item.quest ) )
	pass

func update_quest_details( q : Quest ) -> void:
	clear_quest_details()
	
	title_label.text = q.title
	description_label.text = q.description
	
	if q.icon:
		icon_rect.texture = q.icon
		icon_rect.visible = true
	else:
		icon_rect.visible = false
	
	var quest_save = QuestManager.find_quest(q)
	
	for i in q.steps.size():
		var step : String = q.steps[i]
		var new_step : QuestStepItem = QUEST_STEP_ITEM.instantiate()
		var step_is_complete : bool = false
		var current : int = 0
		var target : int = 1
		
		if quest_save.title != "not found":
			step_is_complete = quest_save.completed_steps.has( step.to_lower() )
			if quest_save.has("step_counts"):
				current = quest_save.step_counts.get( step.to_lower(), 0 )
			if i < q.step_targets.size():
				target = max( q.step_targets[i], 1 )
		
		details_container.add_child( new_step )
		new_step.initialize( step, step_is_complete, current, target )
	pass

func clear_quest_details() -> void:
	title_label.text = ""
	description_label.text = ""
	icon_rect.visible = false
	for c in details_container.get_children():
		if c is QuestStepItem:
			c.queue_free()
