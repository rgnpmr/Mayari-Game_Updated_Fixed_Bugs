class_name DeerPickup extends Area2D
@export var chicken_item : ItemData
var collected : bool = false

func _ready() -> void:
	area_entered.connect( _on_area_enter )
	area_exited.connect( _on_area_exit )

func _on_area_enter( _a : Area2D ) -> void:
	if not PlayerManager.interact_pressed.is_connected( _collect ):
		PlayerManager.interact_pressed.connect( _collect )

func _on_area_exit( _a : Area2D ) -> void:
	if PlayerManager.interact_pressed.is_connected( _collect ):
		PlayerManager.interact_pressed.disconnect( _collect )

func _collect() -> void:
	if collected:
		return
	collected = true
	
	if PlayerManager.INVENTORY_DATA.add_item( chicken_item ):
		get_parent().queue_free()
	else:
		collected = false
