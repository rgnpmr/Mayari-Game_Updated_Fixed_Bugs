@tool
class_name GiveAnimalsTrigger extends QuestNode
@export var item_to_remove : ItemData
@export var item_count : int = 2
@export_category( "Parent Signal Connection" )
@export var signal_name : String = ""

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if signal_name != "" and get_parent().has_signal( signal_name ):
		get_parent().connect( signal_name, _on_triggered )

func _on_triggered() -> void:
	if linked_quest == null:
		return
	if item_to_remove:
		PlayerManager.INVENTORY_DATA.remove_item( item_to_remove, item_count )
	QuestManager.update_quest( "Hanap Manok", "Balik Manok" )
