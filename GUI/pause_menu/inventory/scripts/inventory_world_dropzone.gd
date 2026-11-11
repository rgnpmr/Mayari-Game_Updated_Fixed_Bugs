class_name InventoryWorldDropZone extends ColorRect

func _can_drop_data( _at_position : Vector2, data : Variant ) -> bool:
	return typeof( data ) == TYPE_DICTIONARY and data.has( "slot_data" )

func _drop_data( at_position : Vector2, data : Variant ) -> void:
	var slot_data : SlotData = data.slot_data
	if slot_data == null or slot_data.item_data == null:
		return
	
	var world_pos : Vector2 = get_viewport().get_canvas_transform().affine_inverse() * ( global_position + at_position )
	
	if slot_data.item_data.use_at( world_pos ):
		slot_data.quantity -= 1
	pass
