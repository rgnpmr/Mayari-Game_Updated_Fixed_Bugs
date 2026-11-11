class_name InventorySlotUI extends Button


var slot_data : SlotData : set = set_slot_data

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label


func _ready() -> void:
	texture_rect.texture = null
	label.text = ""
	focus_entered.connect( item_focused )
	focus_exited.connect( item_unfocused )
	pressed.connect( item_pressed )


func set_slot_data( value : SlotData ) -> void:
	slot_data = value 
	if slot_data == null:
		return
	texture_rect.texture =  slot_data.item_data.texture
	label.text = str( slot_data.quantity)


func item_focused() -> void:
	if slot_data != null:
		if slot_data.item_data != null:
			PauseMenu.update_item_description( slot_data.item_data.description )
	pass

func item_unfocused() -> void:
	PauseMenu.update_item_description( "" )
	pass


func item_pressed() -> void:
	if slot_data == null or slot_data.item_data == null:
		return
	
	if PauseMenu.placement_mode:
		PauseMenu.select_item_for_placement( slot_data.item_data )
		return
	
	var was_used = slot_data.item_data.use()
	if was_used == false:
		return
	slot_data.quantity -= 1
	label.text = str( slot_data.quantity )


func _get_drag_data( _at_position : Vector2 ) -> Variant:
	if slot_data == null or slot_data.item_data == null:
		return null
	
	var preview := TextureRect.new()
	preview.texture = slot_data.item_data.texture
	preview.custom_minimum_size = Vector2( 32, 32 )
	set_drag_preview( preview )
	
	return { "source_slot": self, "slot_data": slot_data }

func _can_drop_data( _at_position : Vector2, data : Variant ) -> bool:
	return typeof( data ) == TYPE_DICTIONARY and data.has( "source_slot" )

func _drop_data( _at_position : Vector2, data : Variant ) -> void:
	var source_slot : InventorySlotUI = data.source_slot
	if source_slot == self:
		return
	
	# Swap the two slots' data in the underlying InventoryData array
	var inventory_data : InventoryData = PlayerManager.INVENTORY_DATA
	var self_index := inventory_data.slots.find( slot_data )
	var source_index := inventory_data.slots.find( source_slot.slot_data )
	
	inventory_data.slots[ self_index ] = source_slot.slot_data
	inventory_data.slots[ source_index ] = slot_data
	inventory_data.emit_changed()
	pass
