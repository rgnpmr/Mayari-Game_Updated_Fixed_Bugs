class_name State_Idle extends State

@onready var walk: State = $"../Walk"

#what happens if the player enters this state
func Enter() -> void:
	player.UpdateAnimation("idle")
	pass


#What happens if the playeres exits this state
func Exit() -> void:
	pass


func Process (_delta : float ) -> State:
	if player.direction != Vector2.ZERO:
		return walk
	player.velocity = Vector2.ZERO
	return null

func Physics( _delta : float ) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	# "interact" is already emitted once by Player._unhandled_input, so it is
	# not emitted again here (it used to fire twice per key press).
	return null
