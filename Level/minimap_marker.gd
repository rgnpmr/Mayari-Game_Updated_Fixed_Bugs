class_name MinimapMarker extends Node2D

@export var quest_title : String = ""
@export var marker_color : Color = Color(1.0, 0.55, 0.1)
@export var always_visible : bool = false

func _ready() -> void:
	add_to_group("minimap_marker")
