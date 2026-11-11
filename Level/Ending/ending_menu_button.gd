class_name EndingMenuButton extends StyledButton

@export_file( "*.tscn" ) var main_menu_scene : String = ""


func _ready() -> void:
	SaveManager.delete_save()
	apply_style()

	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP


func _pressed() -> void:
	if main_menu_scene == "":
		push_warning( "EndingMenuButton: no main menu scene is set in the Inspector." )
		return

	disabled = true
	get_tree().paused = false


	var clock = get_node_or_null( "/root/ClockDisplay" )
	if clock and clock.has_method( "hide_hud" ):
		clock.hide_hud()
	var hud = get_node_or_null( "/root/PlayerHud" )
	if hud and hud.has_method( "hide_hud" ):
		hud.hide_hud()

	get_tree().change_scene_to_file( main_menu_scene )
