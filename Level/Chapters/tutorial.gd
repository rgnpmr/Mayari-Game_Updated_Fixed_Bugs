extends Node

func _ready() -> void:
	print("Opening Scene instance ID: ", get_instance_id())
	if PlayerManager.pending_new_game_spawn:
		PlayerManager.pending_new_game_spawn = false
		_play_tutorial()
	else:
		TimeManager.start_clock()

func _exit_tree() -> void:
	# safety: never leave the controls hidden if the scene is left mid-tutorial
	_set_touch_suppressed(false)

func _play_tutorial() -> void:
	var items : Array[DialogueItem] = []
	for c in get_children():
		if c is DialogueItem:
			items.append(c)

	if items.size() > 0:
		_set_touch_suppressed(true)
		await get_tree().process_frame
		DialogueSystem.show_dialogue(items)
		await DialogueSystem.finished
		_set_touch_suppressed(false)

	TimeManager.start_clock()

func _set_touch_suppressed(value: bool) -> void:
	var touch := get_node_or_null("/root/TouchControls")
	if touch:
		touch.suppressed = value
