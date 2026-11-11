extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Default state when spawned or off-screen
	animated_sprite.play("idle")

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	# Switch to fetch animation when entering camera view
	animated_sprite.play("fetch")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Return to idle animation when leaving camera view
	animated_sprite.play("idle")
