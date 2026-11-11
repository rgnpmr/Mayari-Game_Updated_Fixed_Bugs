extends Node

const SAVE_PATH = "user://"
const SAVE_FILE = "save.sav"

# Old quest titles (lowercase) -> current title, so older save files still match
const QUEST_RENAMES : Dictionary = {
	"linig kapaligiran": "Linig",
}

signal game_loaded
signal game_saved


var current_save : Dictionary = {
	scene_path = "",
	player = {
		level = 1,
		xp = 0,
		hp = 1,
		max_hp = 1,
		attack = 1,
		defense = 1,
		pos_x = 0,
		pos_y = 0
	},
	items = [],
	persistance = {},
	quests = [],
}


func save_game() -> void:
	update_player_data()
	update_scene_path()
	update_item_data()
	update_quest_data()
	update_world_data()
	update_time_data()

	var file := FileAccess.open( SAVE_PATH + SAVE_FILE, FileAccess.WRITE )
	if file == null:
		push_warning( "SaveManager: could not open save file for writing (error %d)" % FileAccess.get_open_error() )
		return
	file.store_line( JSON.stringify( current_save ) )
	file.close()

	game_saved.emit()
	print( "save_game: saved %d quests, %d levels of cleared objects, clock day %d at %.3f" % [ current_save.quests.size(), current_save.persistance.size(), current_save.time.day, current_save.time.time_of_day ] )
	pass


func load_game() -> void:
	if not FileAccess.file_exists( SAVE_PATH + SAVE_FILE ):
		push_warning( "SaveManager: no save file found" )
		return

	var file := FileAccess.open( SAVE_PATH + SAVE_FILE, FileAccess.READ )
	if file == null:
		push_warning( "SaveManager: could not open save file for reading (error %d)" % FileAccess.get_open_error() )
		return

	var json := JSON.new()
	if json.parse( file.get_line() ) != OK:
		push_warning( "SaveManager: save file is corrupted" )
		return

	var save_dict : Dictionary = json.get_data() as Dictionary
	current_save = save_dict
	LevelManager.clear_placed_gems()

	# Older saves stored persistance as an Array (or not at all)
	if not ( current_save.get( "persistance" ) is Dictionary ):
		current_save.persistance = {}

	# Restore which pickups / rescued animals are already cleared. This has to
	# happen BEFORE the level loads, because PickUpArea checks it in _ready().
	WorldStateManager.cleared_objects = current_save.persistance.duplicate( true )

	LevelManager.load_new_level( current_save.scene_path, "", Vector2.ZERO )

	await  LevelManager.level_load_started

	PlayerManager.set_player_position( Vector2(current_save.player.pos_x, current_save.player.pos_y ))
	PlayerManager.set_health( current_save.player.hp, current_save.player.max_hp )

	var p : Player = PlayerManager.player
	p.level = current_save.player.level
	p.xp = current_save.player.xp
	p.attack = current_save.player.attack
	p.defense = current_save.player.defense

	PlayerManager.INVENTORY_DATA.parse_save_data( current_save.items )
	QuestManager.current_quests = _clean_loaded_quests( current_save.get( "quests", [] ) )
	# Repair counters in older saves (a step was done but "progress: n/3" stayed 0)
	for q in QuestManager.current_quests:
		QuestManager.sync_amount_with_steps( q )
	print( "load_game: restored %d quests" % QuestManager.current_quests.size() )

	await LevelManager.level_loaded

	# Restore the clock last, so nothing in the level can overwrite it.
	# The clock label is hidden on the main menu and only shown by the Start
	# button's story flow, so Continue has to show it too.
	_restore_time_data()
	ClockDisplay.show_hud()

	game_loaded.emit()

	pass


func update_player_data() -> void:
	var p : Player = PlayerManager.player
	if p == null:
		push_warning( "SaveManager: no player to save" )
		return
	current_save.player.hp = p.hp
	current_save.player.max_hp = p.max_hp
	current_save.player.pos_x = p.global_position.x
	current_save.player.pos_y = p.global_position.y
	current_save.player.level = p.level
	current_save.player.xp = p.xp
	current_save.player.attack = p.attack
	current_save.player.defense = p.defense


func update_scene_path() -> void:
	var p : String = ""
	for c in get_tree().root.get_children():
		if c is Level:
			p = c.scene_file_path
	current_save.scene_path = p
	pass


func update_item_data() -> void:
	current_save.items = PlayerManager.INVENTORY_DATA.get_save_data()



func update_quest_data() -> void:
	# deep copy so the save never shares data with the live quest list
	current_save.quests = QuestManager.current_quests.duplicate( true )


func update_world_data() -> void:
	# cleared pickups / rescued animals, grouped by level scene
	current_save.persistance = WorldStateManager.cleared_objects.duplicate( true )


func update_time_data() -> void:
	current_save.time = {
		day = TimeManager.current_day,
		time_of_day = TimeManager.time_of_day,
		running = TimeManager.clock_running,
	}


func _restore_time_data() -> void:
	var t = current_save.get( "time" )
	if not ( t is Dictionary ):
		# older save without clock data: leave the clock as it is
		print( "load_game: this save has no clock data (it was saved before clock saving was added). Press Save again, then reload." )
		return
	TimeManager.restore_time(
		int( t.get( "day", 1 ) ),
		float( t.get( "time_of_day", 0.3 ) ),
		bool( t.get( "running", false ) )
	)
	print( "load_game: restored clock day %d at %.3f (running: %s)" % [ TimeManager.current_day, TimeManager.time_of_day, str( TimeManager.clock_running ) ] )

# True when there is a saved game to continue
func has_save() -> bool:
	return FileAccess.file_exists( SAVE_PATH + SAVE_FILE )


# Called when the game is finished: erases the saved game and everything
# remembered from that run, so only Start works afterwards.
func delete_save() -> void:
	if has_save():
		var err : int = DirAccess.remove_absolute( SAVE_PATH + SAVE_FILE )
		if err != OK:
			push_warning( "SaveManager: could not delete the save file (error %d)" % err )
	current_save.scene_path = ""
	reset_for_new_game()

# Call from the New Game button before the first level loads, so nothing from
# a previous run (cleared pickups, quests) carries over.
func reset_for_new_game() -> void:
	WorldStateManager.cleared_objects = {}
	current_save.persistance = {}
	QuestManager.current_quests = []
	current_save.quests = []
	TimeManager.reset_time()
	LevelManager.clear_placed_gems()


# JSON turns every number into a float, and old saves can hold renamed or
# deleted quests. Rebuild each saved quest into the shape QuestManager expects.
func _clean_loaded_quests( raw : Array ) -> Array:
	var result : Array = []
	for entry in raw:
		if not ( entry is Dictionary ) or not entry.has( "title" ):
			continue

		var q : Dictionary = entry.duplicate( true )

		var key : String = str( q.title ).strip_edges().to_lower()
		if QUEST_RENAMES.has( key ):
			q.title = QUEST_RENAMES[ key ]

		if QuestManager.find_quest_by_title( q.title ) == null:
			push_warning( "SaveManager: dropping saved quest with unknown title '%s'" % q.title )
			continue

		q.is_complete = bool( q.get( "is_complete", false ) )
		q.amount = int( q.get( "amount", 0 ) )

		if not q.has( "completed_steps" ):
			q.completed_steps = []

		var counts : Dictionary = {}
		var saved_counts : Dictionary = q.get( "step_counts", {} )
		for k in saved_counts:
			counts[ k ] = int( saved_counts[ k ] )
		q.step_counts = counts

		result.append( q )
	return result
