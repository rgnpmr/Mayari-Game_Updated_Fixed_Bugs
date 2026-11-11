class_name State extends Node
var player : Player
var state_machine: PlayerStateMachine

func _ready() -> void:
	pass 

func init() -> void:
	pass

#what happens if the player enters this state
func Enter() -> void:
	pass

#What happens if the playeres exits this state
func Exit() -> void:
	pass

func Process (_delta : float ) -> State:
	return null

func Physics( _delta : float ) -> State:
	return null

func HandleInput ( _event : InputEvent ) -> State:
	return null
