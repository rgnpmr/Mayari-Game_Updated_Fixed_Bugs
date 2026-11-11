extends AudioStreamPlayer2D

@export var play_locate_sound : bool = false

func _ready() -> void:
	if play_locate_sound:
		play()
		finished.connect( func(): play() )
	pass
