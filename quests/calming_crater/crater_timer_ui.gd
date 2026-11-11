extends CanvasLayer

@onready var timer_label : Label = $TimerLabel

func _ready() -> void:
	visible = false

func connect_to_challenge( challenge : Node ) -> void:
	challenge.time_updated.connect( _on_time_updated )
	challenge.challenge_succeeded.connect( _on_finished )
	challenge.challenge_failed.connect( _on_finished )
	visible = true

func _on_time_updated( remaining : float, total : float ) -> void:
	var minutes := int( remaining ) / 60
	var seconds := int( remaining ) % 60
	timer_label.text = "%01d:%02d" % [ minutes, seconds ]

func _on_finished() -> void:
	visible = false
