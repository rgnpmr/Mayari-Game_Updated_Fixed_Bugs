extends Node

@export var quest_title : String = "Calming the Crater"
@export var pulse_interval_min : float = 3.0
@export var pulse_interval_max : float = 7.0
@export var pulse_strength_min : float = 0.3
@export var pulse_strength_max : float = 0.7

var quest_active : bool = true
var pulse_timer : Timer

func _ready() -> void:
	QuestManager.quest_updated.connect( _on_quest_updated )
	
	pulse_timer = Timer.new()
	add_child( pulse_timer )
	pulse_timer.one_shot = true
	pulse_timer.timeout.connect( _on_pulse_timeout )
	_schedule_next_pulse()

func _schedule_next_pulse() -> void:
	if not quest_active:
		return
	pulse_timer.wait_time = randf_range( pulse_interval_min, pulse_interval_max )
	pulse_timer.start()

func _on_pulse_timeout() -> void:
	if quest_active:
		var strength : float = randf_range( pulse_strength_min, pulse_strength_max )
		PlayerManager.shake_camera( strength )
	_schedule_next_pulse()

func _on_quest_updated( q ) -> void:
	if q.title.to_lower() != quest_title.to_lower():
		return
	if q.is_complete:
		quest_active = false
