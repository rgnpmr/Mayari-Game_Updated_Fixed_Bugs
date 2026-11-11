extends Node

signal day_changed( new_day : int )
signal time_of_day_changed( new_time : float ) 

const START_DAY : int = 1
const START_TIME : float = 0.3

@export var day_length_seconds : float = 120.0  # real seconds per in-game day
@export var morning_time : float = 0.25  # what "morning" means (0.25 = roughly 6am)

var current_day : int = START_DAY
var time_of_day : float = START_TIME
var clock_running : bool = false

func _process( delta : float ) -> void:
	if not clock_running:
		return
	time_of_day += delta / day_length_seconds
	if time_of_day >= 1.0:
		time_of_day = fmod( time_of_day, 1.0 )
		advance_day()
	time_of_day_changed.emit( time_of_day )

func start_clock() -> void:
	clock_running = true

func pause_clock() -> void:
	clock_running = false

func advance_day() -> void:
	current_day += 1
	day_changed.emit( current_day )
	print( "Day advanced to: ", current_day )
	pass

func skip_to_morning() -> void:
	time_of_day = morning_time
	advance_day()
	time_of_day_changed.emit( time_of_day )
	pass


# Used by SaveManager after a load. Emits time_of_day_changed so the clock label
# redraws right away. It does NOT emit day_changed, so "new day" events don't
# fire just because a save was loaded.
func restore_time( day : int, t : float, running : bool ) -> void:
	current_day = max( day, 1 )
	time_of_day = clampf( t, 0.0, 0.999999 )
	clock_running = running
	time_of_day_changed.emit( time_of_day )


# Used by SaveManager when a New Game starts
func reset_time() -> void:
	current_day = START_DAY
	time_of_day = START_TIME
	clock_running = false
	time_of_day_changed.emit( time_of_day )
