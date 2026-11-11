@tool
class_name VillagerEvacuateOnQuestComplete extends NPCBehavior

@export var quest_title : String = ""
@export var walk_speed : float = 40.0
@export var walk_direction : Vector2 = Vector2.DOWN
@export var walk_duration : float = 2.0

var should_evacuate : bool = false
var has_evacuated : bool = false
var dialogue_interaction : DialogueInteraction
var unique_id : String = ""

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	super()
	
	unique_id = str( get_path() )
	if WorldStateManager.is_cleared( unique_id ):
		npc.queue_free()
		return
	
	for c in npc.get_children():
		if c is DialogueInteraction:
			dialogue_interaction = c
	
	if quest_title != "":
		QuestManager.quest_rewarded.connect( _on_quest_rewarded )
	pass

func _on_quest_rewarded( _title : String ) -> void:
	if _title.to_lower() == quest_title.to_lower():
		should_evacuate = true
	pass

func start() -> void:
	if not should_evacuate or has_evacuated:
		return
	has_evacuated = true
	
	npc.do_behavior = false
	if dialogue_interaction:
		dialogue_interaction.enabled = false
	
	npc.state = "walk"
	npc.direction = walk_direction
	npc.update_direction_name()
	if npc.direction_name == "side" and npc.direction.x < 0:
		npc.sprite.flip_h = true
	else:
		npc.sprite.flip_h = false
	npc.update_animation()
	npc.velocity = walk_direction.normalized() * walk_speed
	
	var elapsed := 0.0
	var max_wait := 10.0
	while _is_on_screen() and elapsed < max_wait:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	
	WorldStateManager.mark_cleared( unique_id )
	npc.queue_free()
	pass

func _is_on_screen() -> bool:
	var viewport_rect := npc.get_viewport_rect()
	var camera := npc.get_viewport().get_camera_2d()
	if camera == null:
		return false
	var screen_pos := npc.global_position - camera.get_screen_center_position() + viewport_rect.size / 2.0
	return viewport_rect.has_point( screen_pos )
