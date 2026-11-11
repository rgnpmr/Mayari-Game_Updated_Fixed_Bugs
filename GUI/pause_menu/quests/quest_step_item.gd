class_name QuestStepItem extends Control

@onready var label: Label = $Label
@onready var sprite_2d: Sprite2D = $Sprite2D

func initialize( step : String, is_complete : bool, current : int = 0, target : int = 1 ) -> void:
	if target > 1:
		label.text = step + ": " + str(current) + "/" + str(target)
	else:
		label.text = step
	
	if is_complete == true:
		sprite_2d.frame = 1
	else:
		sprite_2d.frame = 0
	pass
