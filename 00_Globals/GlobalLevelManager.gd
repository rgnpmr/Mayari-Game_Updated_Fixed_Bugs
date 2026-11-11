extends Node2D

var current_tilemap_bounds : Array [ Vector2 ] 
var chapter_transition : String
var target_transition : String 
var position_offset : Vector2
var last_failed_level_path : String = ""

# Gems placed into sockets, so Try Again can give them back
var placed_gems : Array = []

# NEW: level path -> seconds left on the crater timer
var challenge_time_left : Dictionary = {}

signal level_load_started
signal level_loaded
signal TileMapBoundsChanged( bounds : Array[ Vector2 ] )


func _ready() -> void:
	pass


func ChangeTilemapBounds( bounds : Array [ Vector2 ]) -> void:
	current_tilemap_bounds = bounds
	TileMapBoundsChanged.emit( bounds )

func load_new_level(
	level_path : String,
	_target_transition : String, 
	_position_offset : Vector2
) -> void:  
	
	print("=== load_new_level called with: ", level_path, " ===")
	
	get_tree().paused = true
	target_transition = _target_transition
	position_offset = _position_offset
	
	await SceneTransition.fade_out()
	
	level_load_started.emit()
	
	await get_tree().process_frame
	
	var _err : int = get_tree().change_scene_to_file( level_path )
	if _err != OK:
		push_error( "Failed to load level: " + level_path + " (error code " + str(_err) + ")" )
		await SceneTransition.fade_in()
		get_tree().paused = false
		return
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	await SceneTransition.fade_in()
	
	get_tree().paused = false
	
	await get_tree().process_frame
	
	level_loaded.emit()
	
	pass


# Called by a GemSocket each time a gem is placed.
# CHANGED: it now receives the level path from the socket.
func register_placed_gem( item : ItemData, q_title : String, q_step : String, level_path : String ) -> void:
	placed_gems.append( {
		"item": item,
		"quest": q_title,
		"step": q_step,
		"level": level_path
	} )

# NEW: true when this gem was already placed in this level (used when coming back to it)
func is_gem_placed( level_path : String, item : ItemData, q_step : String ) -> bool:
	for g in placed_gems:
		if g.level == level_path and g.item == item and g.step == q_step:
			return true
	return false

# Gives the gems of that level back and undoes their quest steps
func restore_placed_gems( level_path : String ) -> void:
	for g in placed_gems:
		if g.level != level_path:
			continue
		PlayerManager.INVENTORY_DATA.add_item( g.item, 1 )
		_undo_quest_step( g.quest, g.step )
	placed_gems.clear()
	challenge_time_left.erase( level_path )   # NEW: Try Again starts the timer fresh

func clear_placed_gems() -> void:
	placed_gems.clear()
	challenge_time_left.clear()   # NEW

func _undo_quest_step( q_title : String, q_step : String ) -> void:
	if q_title == "" or q_step == "":
		return
	var i : int = QuestManager.get_quest_index_by_title( q_title )
	if i == -1:
		return
	var q = QuestManager.current_quests[ i ]
	var key : String = q_step.to_lower()
	q.completed_steps.erase( key )
	if q.has( "step_counts" ):
		q.step_counts.erase( key )
	q.is_complete = false
	QuestManager.sync_amount_with_steps( q )
	QuestManager.quest_updated.emit( q )
