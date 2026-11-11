extends Node

@export var quest_title : String = "Kalma"
@export var time_limit : float = 90.0

@onready var timer : Timer = $Timer

var time_remaining : float = 0.0
var challenge_active : bool = false
var _level_key : String = ""

signal challenge_failed
signal challenge_succeeded
signal time_updated( remaining : float, total : float )

func _ready() -> void:
	_level_key = _get_level_key()
	timer.wait_time = time_limit
	timer.one_shot = true
	timer.timeout.connect( _on_timer_timeout )

	QuestManager.quest_updated.connect( _on_quest_updated )

	# Start only if the quest is running and not finished yet
	var index : int = QuestManager.get_quest_index_by_title( quest_title )
	if index != -1 and not QuestManager.current_quests[ index ].is_complete:
		_start_challenge()

func _get_level_key() -> String:
	var root : Node = owner if owner != null else get_tree().current_scene
	return root.scene_file_path if root != null else ""

func _start_challenge() -> void:
	if challenge_active:
		return
	challenge_active = true
	# Coming back to the level: continue from the time that was left
	time_remaining = float( LevelManager.challenge_time_left.get( _level_key, time_limit ) )
	timer.start( maxf( time_remaining, 0.1 ) )

func _process( delta : float ) -> void:
	if not challenge_active:
		return
	time_remaining = max( 0.0, time_remaining - delta )
	time_updated.emit( time_remaining, time_limit )

func _on_quest_updated( q ) -> void:
	if q.title != quest_title:
		return

	if not challenge_active:
		if not q.is_complete:
			_start_challenge()
		return

	if q.is_complete:
		_on_challenge_succeeded()

func _on_challenge_succeeded() -> void:
	if not challenge_active:
		return
	challenge_active = false
	timer.stop()
	LevelManager.challenge_time_left.erase( _level_key )
	challenge_succeeded.emit()

func _on_timer_timeout() -> void:
	if not challenge_active:
		return
	challenge_active = false
	LevelManager.challenge_time_left.erase( _level_key )
	challenge_failed.emit()

	get_tree().paused = true

	FloodEffect.flood_completed.connect( _on_flood_finished, CONNECT_ONE_SHOT )
	FloodEffect.start_flood()

func _on_flood_finished() -> void:
	var tree := get_tree()
	LevelManager.last_failed_level_path = tree.current_scene.scene_file_path
	tree.paused = false
	tree.change_scene_to_file( "res://GUI/GameOver/gameover.tscn" )

# Leaving the level (a chapter transition, for example): remember the time left
func _exit_tree() -> void:
	if challenge_active:
		LevelManager.challenge_time_left[ _level_key ] = time_remaining
