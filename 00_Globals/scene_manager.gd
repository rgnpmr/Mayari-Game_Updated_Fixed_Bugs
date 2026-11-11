extends Node
## Autoload: add this in Project Settings -> Globals (Autoload) with the name "SceneManager"

signal scene_changing( path : String )

var is_changing : bool = false


func change_scene( path : String ) -> void:
	if is_changing:
		return

	if not ResourceLoader.exists( path ):
		push_error( "SceneManager: scene not found: " + path )
		return

	is_changing = true
	scene_changing.emit( path )

	# Wait one frame so the scene that called us can finish its own cleanup
	await get_tree().process_frame

	var err : Error = get_tree().change_scene_to_file( path )
	if err != OK:
		push_error( "SceneManager: could not load " + path )

	is_changing = false
