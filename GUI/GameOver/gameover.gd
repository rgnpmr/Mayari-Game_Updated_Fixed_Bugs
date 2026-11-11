extends Control

@onready var retry_button: Button = $CanvasLayer/RetryButton
@onready var main_menu_button: Button = $CanvasLayer/MainMenuButton


func _ready() -> void:
	retry_button.pressed.connect( _on_retry_pressed )
	main_menu_button.pressed.connect( _on_main_menu_pressed )
	
	QuestView.hide()
	QuestView.process_mode = Node.PROCESS_MODE_DISABLED
	MiniMapUI.hide()
	MiniMapUI.process_mode = Node.PROCESS_MODE_DISABLED

func _on_retry_pressed() -> void:
	# NEW: give the used gems back and undo their Kalma steps
	LevelManager.restore_placed_gems( LevelManager.last_failed_level_path )
	
	QuestView.show()
	QuestView.process_mode = Node.PROCESS_MODE_INHERIT
	MiniMapUI.show()
	MiniMapUI.process_mode = Node.PROCESS_MODE_INHERIT
	if LevelManager.last_failed_level_path != "":
		get_tree().change_scene_to_file( LevelManager.last_failed_level_path )
	else:
		get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	LevelManager.clear_placed_gems()   # NEW
	QuestView.show()
	QuestView.process_mode = Node.PROCESS_MODE_INHERIT
	MiniMapUI.show()
	MiniMapUI.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().change_scene_to_file( "res://Level/Chapters/main_menu.tscn" )
