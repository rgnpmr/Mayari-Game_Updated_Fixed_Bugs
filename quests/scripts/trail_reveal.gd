extends Line2D

@export var quest_title : String = ""

func _ready() -> void:
	QuestManager.quest_updated.connect( _on_quest_updated )
	_check_already_complete()
	pass

func _check_already_complete() -> void:
	if quest_title == "":
		return
	var quest_data = QuestManager.find_quest_by_title( quest_title )
	if quest_data == null:
		return
	var q = QuestManager.find_quest( quest_data )
	if q.is_complete:
		reveal_trail()
	pass

func _on_quest_updated( q ) -> void:
	if quest_title != "" and q.title.to_lower() == quest_title.to_lower() and q.is_complete:
		reveal_trail()
	pass

func reveal_trail() -> void:
	visible = true
	modulate.a = 0.0
	var fade_in = create_tween()
	fade_in.tween_property( self, "modulate:a", 1.0, 1.5 )
	fade_in.finished.connect( start_pulse )
	pass

func start_pulse() -> void:
	var pulse = create_tween()
	pulse.set_loops()
	pulse.tween_property( self, "modulate:a", 0.4, 0.8 ).set_trans( Tween.TRANS_SINE )
	pulse.tween_property( self, "modulate:a", 1.0, 0.8 ).set_trans( Tween.TRANS_SINE )
	pass
