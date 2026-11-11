class_name NotificationUI
extends CanvasLayer

var notification_queue : Array
@onready var panel_container: PanelContainer = $Control/PanelContainer
@onready var animation_player: AnimationPlayer = $Control/AnimationPlayer
@onready var title_label: Label = $Control/PanelContainer/VBoxContainer/Label
@onready var message_label: Label = $Control/PanelContainer/VBoxContainer/Label2

func _ready() -> void:
	panel_container.visible = false
	panel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animation_player.animation_finished.connect( notification_animation_finished )

func add_notification_to_queue( _title : String, _message : String ) -> void:
	print('NOTIFICATION QUEUED: ', _title)
	notification_queue.append({
		title = _title,
		message = _message
	})
	if animation_player.is_playing():
		return
	display_notification()
	pass

func display_notification() -> void:
	var _n = notification_queue.pop_front()
	if _n == null:
		panel_container.visible = false
		panel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	title_label.text = _n.title
	message_label.text = _n.message
	# An empty title or message takes no space, so there is no blank line
	title_label.visible = _n.title != ""
	message_label.visible = _n.message != ""
	animation_player.play( "show_notification" )
	pass

func notification_animation_finished( _a : String )-> void:
	display_notification()
