extends CanvasLayer

signal shown
signal hidden
signal item_selected_for_placement( item : ItemData )
signal item_placement_cancelled

@onready var audio_stream_player: AudioStreamPlayer = $Control/AudioStreamPlayer

@onready var tab_container: TabContainer = $Control/TabContainer
@onready var close_button: Button = $Control/CloseButton

@onready var button_save: Button = $Control/TabContainer/System/VBoxContainer/Button_Save
@onready var button_quit: Button = $Control/TabContainer/System/VBoxContainer/Button_Quit

@onready var music_slider: HSlider = $Control/TabContainer/System/VBoxContainer/SettingsCard/SettingsContent/MusicRow/MusicSlider
@onready var music_percent_label: Label = $Control/TabContainer/System/VBoxContainer/SettingsCard/SettingsContent/MusicRow/MusicPercentLabel
@onready var music_mute_button: Button = $Control/TabContainer/System/VBoxContainer/SettingsCard/SettingsContent/MusicRow/MusicMuteButton

@onready var ambience_slider: HSlider = $Control/TabContainer/System/VBoxContainer/SettingsCard/SettingsContent/AmbienceRow/AmbienceSlider
@onready var ambience_percent_label: Label = $Control/TabContainer/System/VBoxContainer/SettingsCard/SettingsContent/AmbienceRow/AmbiencePercentLabel
@onready var ambience_mute_button: Button = $Control/TabContainer/System/VBoxContainer/SettingsCard/SettingsContent/AmbienceRow/AmbienceMuteButton

@onready var item_description: Label = $Control/TabContainer/Inventory/ItemDescription

var is_paused : bool = false
var placement_mode : bool = false

var music_bus_index : int = AudioServer.get_bus_index("Music")
var ambience_bus_index : int = AudioServer.get_bus_index("Ambience")



func _ready() -> void:
	hide_pause_menu()
	button_save.pressed.connect( _on_save_pressed )
	button_quit.pressed.connect( _on_quit_pressed )
	close_button.pressed.connect( _on_close_pressed )
	
	_connect_hover( button_save )
	_connect_hover( button_quit )
	_connect_hover( close_button )
	
	music_slider.value_changed.connect( _on_music_slider_changed )
	ambience_slider.value_changed.connect( _on_ambience_slider_changed )
	music_mute_button.toggled.connect( _on_music_mute_toggled )
	ambience_mute_button.toggled.connect( _on_ambience_mute_toggled )
	
	music_slider.value = 100
	ambience_slider.value = 100


func _connect_hover( button : Button ) -> void:
	button.mouse_entered.connect( func(): _on_button_hover_start( button ) )
	button.mouse_exited.connect( func(): _on_button_hover_end( button ) )

func _on_button_hover_start( button : Button ) -> void:
	var _tween := create_tween()
	_tween.tween_property( button, "modulate", Color(1.3, 1.3, 1.1), 0.1 )

func _on_button_hover_end( button : Button ) -> void:
	var _tween := create_tween()
	_tween.tween_property( button, "modulate", Color(1, 1, 1), 0.1 )


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	
	if is_paused:
		if event.is_action_pressed("right_bumper"):
			change_tab( 1 )
		elif event.is_action_pressed("left_bumper"):
			change_tab( -1 )

func show_pause_menu() -> void:
	get_tree().paused = true
	visible = true
	is_paused = true
	tab_container.current_tab = 0
	shown.emit()


func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	is_paused = false
	hidden.emit()


func toggle_pause() -> void:
	if is_paused:
		if placement_mode:
			cancel_item_placement()
		hide_pause_menu()
	else:
		if DialogueSystem.is_active:
			return
		if placement_mode:
			return
		show_pause_menu()


func _on_close_pressed() -> void:
	if not is_paused:
		return
	if placement_mode:
		cancel_item_placement()
	hide_pause_menu()


func _on_save_pressed() -> void:
	if is_paused == false:
		return
	SaveManager.save_game()
	hide_pause_menu()
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()

func update_item_description( new_text : String ) -> void:
	item_description.text = new_text


func play_audio( audio : AudioStream ) -> void:
	audio_stream_player.stream = audio
	audio_stream_player.play()


func change_tab( _i : int = 1 ) -> void:
	tab_container.current_tab = wrapi(
		tab_container.current_tab + _i,
		0,
		tab_container.get_tab_count()
	)
	tab_container.get_tab_bar().grab_focus()

func open_inventory_tab() -> void:
	tab_container.current_tab = tab_container.get_tab_idx_from_control(
		$Control/TabContainer/Inventory
	)

func start_item_placement() -> void:
	placement_mode = true
	show_pause_menu()
	tab_container.current_tab = tab_container.get_tab_idx_from_control(
		$Control/TabContainer/Inventory
	)


func select_item_for_placement( item : ItemData ) -> void:
	if not placement_mode:
		return
	placement_mode = false
	hide_pause_menu()
	item_selected_for_placement.emit( item )


func cancel_item_placement() -> void:
	placement_mode = false
	item_placement_cancelled.emit()


func _on_music_slider_changed( value : float ) -> void:
	music_percent_label.text = str( int(value) ) + "%"
	if music_bus_index != -1:
		var _db : float = linear_to_db( value / 100.0 ) if value > 0 else -80.0
		AudioServer.set_bus_volume_db( music_bus_index, _db )

func _on_ambience_slider_changed( value : float ) -> void:
	ambience_percent_label.text = str( int(value) ) + "%"
	if ambience_bus_index != -1:
		var _db : float = linear_to_db( value / 100.0 ) if value > 0 else -80.0
		AudioServer.set_bus_volume_db( ambience_bus_index, _db )

func _on_music_mute_toggled( muted : bool ) -> void:
	if music_bus_index != -1:
		AudioServer.set_bus_mute( music_bus_index, muted )

func _on_ambience_mute_toggled( muted : bool ) -> void:
	if ambience_bus_index != -1:
		AudioServer.set_bus_mute( ambience_bus_index, muted )
