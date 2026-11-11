extends Node

signal quest_started( q )
signal quest_updated( q )
signal quest_rewarded( _title : String )

const  QUEST_DATA_LOCATION : String = "res://quests/"

# Quests whose collected items (the rescued animals) leave the inventory when
# the quest completes. Lowercase titles. Hanap Manok is NOT here on purpose: its
# chickens are already handed over by the Boy's GiveAnimalsTrigger.
const CONSUME_ITEMS_ON_COMPLETE : Array[String] = [ "likas hayop", "natatadang hayop" ]


# Notification titles. Change the wording here and it updates everywhere.
const TXT_QUEST_STARTED : String = "Misyon"
const TXT_QUEST_UPDATED : String = "Misyon"
const TXT_QUEST_COMPLETE : String = "Natapos ang Misyon!"
const TXT_QUEST_REWARD : String = "Gantimpala!"

var quests : Array[ Quest ]
var current_quests : Array = [] 


func _ready() -> void:
	print("QuestManager _ready() called!")
	gather_quest_data()
	pass


func gather_quest_data() -> void:
	quests.clear()
	_scan_quest_dir( QUEST_DATA_LOCATION )
	print( "quest count: ", quests.size() )
	pass


# Recursively loads every Quest resource under the given folder.
func _scan_quest_dir( path : String ) -> void:
	for d in DirAccess.get_directories_at( path ):
		_scan_quest_dir( path.path_join( d ) )

	for f in DirAccess.get_files_at( path ):
		# Editor may list "x.tres.uid"; exported builds list "x.tres.remap"
		if f.ends_with( ".uid" ):
			continue
		if f.ends_with( ".remap" ):
			f = f.trim_suffix( ".remap" )
		if not ( f.ends_with( ".tres" ) or f.ends_with( ".res" ) ):
			continue
		var res = load( path.path_join( f ) )
		if res is Quest:
			quests.append( res )
		else:
			push_warning( "QuestManager: not a Quest resource: " + path.path_join( f ) )


# Case/whitespace-insensitive title key
func _norm( s : String ) -> String:
	return s.strip_edges().to_lower()


# Update the status of a quest (for step-based quests)
func update_quest( _title : String, _completed_step : String = "", _is_complete : bool = false ) -> void:
	# Fail loudly if the quest has no matching resource, instead of half-working
	if find_quest_by_title( _title ) == null:
		return

	var quest_index : int = get_quest_index_by_title( _title )
	if quest_index == -1:
		var _new_quest : Dictionary = { 
				title = _title,
				is_complete = _is_complete,
				completed_steps = [],
				amount = 0,
				step_counts = {}
		}
		
		if _completed_step != "":
			_new_quest.completed_steps.append( _completed_step.to_lower() )
			sync_amount_with_steps( _new_quest )
		
		current_quests.append( _new_quest )
		quest_updated.emit( _new_quest )
		quest_started.emit( _new_quest )
		
		NotificationManager.add_notification_to_queue( TXT_QUEST_STARTED, _title )
		
		if _new_quest.is_complete == true:
			var quest_res : Quest = find_quest_by_title( _title )
			if quest_res:
				disperse_quest_rewards( quest_res )
			else:
				push_warning("Quest '%s' marked complete but no matching Quest resource found" % _title)
		pass
	else:
		var q = current_quests[ quest_index ]
		if _completed_step != "" and q.completed_steps.has( _completed_step.to_lower() ) == false:
			q.completed_steps.append( _completed_step.to_lower() )
			sync_amount_with_steps( q )
			
			var quest_data : Quest = find_quest_by_title( _title )
			if quest_data and quest_data.auto_complete_on_all_steps and quest_data.steps.size() > 0 and q.completed_steps.size() >= quest_data.steps.size():
				_is_complete = true
			
			pass
		q.is_complete = _is_complete
		
		quest_updated.emit( q )
		
		if q.is_complete == true:
			NotificationManager.add_notification_to_queue(TXT_QUEST_COMPLETE, _title)
			var quest_res : Quest = find_quest_by_title( _title )
			if quest_res:
				disperse_quest_rewards( quest_res )
			else:
				push_warning("Quest '%s' marked complete but no matching Quest resource found" % _title)
	# No notification for a plain step update, only for start and complete
	pass


func increment_quest_progress( _title : String, _amount : int = 1 ) -> void:
	var quest_index : int = get_quest_index_by_title( _title )
	if quest_index == -1:
		return

	var q = current_quests[ quest_index ]
	if q.is_complete:
		return

	if not q.has("amount"):
		q["amount"] = 0

	var quest_data : Quest = find_quest_by_title( _title )
	if quest_data == null or quest_data.target_amount <= 0:
		return

	if q.amount >= quest_data.target_amount:
		return  # already fully collected, waiting on return step

	q.amount = min( q.amount + _amount, quest_data.target_amount )
	quest_updated.emit( q )

	if q.amount >= quest_data.target_amount:
		if quest_data.steps.size() > 0:
			var first_step : String = quest_data.steps[0].to_lower()
			if not q.completed_steps.has( first_step ):
				q.completed_steps.append( first_step )
				quest_updated.emit( q )
				if quest_data.auto_complete_on_all_steps and q.completed_steps.size() >= quest_data.steps.size():
					q.is_complete = true
					disperse_quest_rewards( quest_data )
		else:
			q.is_complete = true
			disperse_quest_rewards( quest_data )
	pass


# Advance a specific named step by a given amount, requiring a target count before it's marked complete
func advance_step( _title : String, _step_name : String, _amount : int = 1 ) -> void:
	var quest_index : int = get_quest_index_by_title( _title )
	if quest_index == -1:
		return
	
	var q = current_quests[ quest_index ]
	if q.is_complete:
		return
	
	var quest_data : Quest = find_quest_by_title( _title )
	if quest_data == null:
		return
	
	var key : String = _step_name.to_lower()
	var step_index : int = -1
	for i in quest_data.steps.size():
		if quest_data.steps[i].to_lower() == key:
			step_index = i
			break
	if step_index == -1:
		return
	
	var target : int = 1
	if step_index < quest_data.step_targets.size():
		target = max( quest_data.step_targets[ step_index ], 1 )
	
	if not q.has("step_counts"):
		q["step_counts"] = {}
	
	var current : int = q.step_counts.get( key, 0 )
	if current >= target:
		return
	
	current = min( current + _amount, target )
	q.step_counts[ key ] = current
	
	if current >= target and not q.completed_steps.has( key ):
		q.completed_steps.append( key )
		sync_amount_with_steps( q )
		if quest_data.auto_complete_on_all_steps and q.completed_steps.size() >= quest_data.steps.size():
			q.is_complete = true
			NotificationManager.add_notification_to_queue( TXT_QUEST_COMPLETE, _title )
			disperse_quest_rewards( quest_data )
	
	quest_updated.emit( q )
	pass


# For quests where every step is one unit of the counter (Hanap Perlas: Berde,
# Asul, Pula = 3 of 3), keep the "progress: n/3" counter in step with the
# completed steps. Quests that don't fit that shape are left alone.
func sync_amount_with_steps( q ) -> void:
	var quest_data : Quest = find_quest_by_title( q.title )
	if quest_data == null:
		return
	if quest_data.target_amount > 0 and quest_data.target_amount == quest_data.steps.size():
		q.amount = min( q.completed_steps.size(), quest_data.target_amount )


# Called by a pickup each time the player collects an item for a quest. For the
# quests listed in CONSUME_ITEMS_ON_COMPLETE it remembers what was collected
# (inside the quest's saved data, so it survives save and load).
func track_collected_item( _title : String, _item : ItemData, _count : int = 1 ) -> void:
	if _item == null or _item.resource_path == "":
		return
	if not CONSUME_ITEMS_ON_COMPLETE.has( _norm( _title ) ):
		return
	var quest_index : int = get_quest_index_by_title( _title )
	if quest_index == -1:
		return
	var q = current_quests[ quest_index ]
	if not q.has( "collected_items" ):
		q["collected_items"] = {}
	var path : String = _item.resource_path
	q.collected_items[ path ] = int( q.collected_items.get( path, 0 ) ) + _count


# Removes everything track_collected_item remembered from the inventory.
func _consume_collected_items( _title : String ) -> void:
	if not CONSUME_ITEMS_ON_COMPLETE.has( _norm( _title ) ):
		return
	var quest_index : int = get_quest_index_by_title( _title )
	if quest_index == -1:
		return
	var q = current_quests[ quest_index ]
	if not q.has( "collected_items" ):
		return
	for path in q.collected_items:
		var item = load( path )
		if item is ItemData:
			PlayerManager.INVENTORY_DATA.remove_item( item, int( q.collected_items[ path ] ) )
	q.collected_items = {}


func disperse_quest_rewards( _q : Quest ) -> void:
	if _q == null:
		push_warning("disperse_quest_rewards called with null quest")
		return

	# Leveling is not used in this game: quests give no XP and the reward popup
	# never mentions it, whatever the quest's Reward XP field says.
	var _parts : PackedStringArray = []
	for i in _q.reward_items:
		if i == null or i.item == null:
			continue
		PlayerManager.INVENTORY_DATA.add_item( i.item, i.quantity )
		_parts.append( i.item.name + " x" + str( i.quantity ) )
		if i.item.quest_title != "" and i.item.quest_step_id != "":
			advance_step( i.item.quest_title, i.item.quest_step_id, i.quantity )

	# Nothing to announce for a quest with no rewards
	if _parts.size() > 0:
		NotificationManager.add_notification_to_queue(TXT_QUEST_REWARD, ", ".join( _parts ) )
	_consume_collected_items( _q.title )
	print("emitting quest_rewarded for: ", _q.title)
	quest_rewarded.emit( _q.title )
	pass

func find_quest( _quest : Quest ) -> Dictionary:
	var key : String = _norm( _quest.title )
	for q in current_quests:
		if _norm( q.title ) == key:
			return q
	return { title = "not found", is_complete = false, completed_steps = [''], amount = 0 }


func find_quest_by_title( _title : String ) -> Quest:
	var key : String = _norm( _title )
	for q in quests:
		if _norm( q.title ) == key:
			return q
	push_warning( "QuestManager: no quest resource found for title '%s'" % _title )
	return null


func get_quest_index_by_title( _title : String ) -> int:
	var key : String = _norm( _title )
	for i in current_quests.size():
		if _norm( current_quests[ i ].title ) == key:
			return i
	return -1


func sort_quests() -> void:
	var active_quests : Array = []
	var completed_quests : Array = []
	for q in current_quests:
		if q.is_complete:
			completed_quests.append( q )
		else:
			active_quests.append( q )
	
	active_quests.sort_custom( sort_quests_ascending )
	completed_quests.sort_custom( sort_quests_ascending )
	
	current_quests = active_quests
	current_quests.append_array( completed_quests )
	pass


func sort_quests_ascending( a, b ):
	if a.title < b.title:
		return true
	return false
