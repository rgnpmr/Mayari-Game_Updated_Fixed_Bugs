extends CanvasLayer

const CONTROLS_HINT : PackedScene = preload("res://GUI/Controls/controls_UI.tscn")

# Same check box picture as the Berde / Asul / Pula list in the pause menu.
# If checkbox.png holds both pictures side by side (or one above the other),
# the script cuts it in half automatically: unchecked first, checked second.
# If you have two separate images, put the checked one in the second path.
const CHECKBOX_PATH : String = "res://GUI/pause_menu/quests/checkbox.png"
const CHECKBOX_CHECKED_PATH : String = ""
# The check box is as tall as the step text plus this many pixels. Raise it for a bigger box.
const CHECKBOX_EXTRA_SIZE : float = 2.0

@onready var panel : Control = $Control
@onready var panel_container : PanelContainer = $Control/PanelContainer
@onready var toggle_button : Button = $IconsContainer/ToggleButton
@onready var prev_button : Button = $Control/PanelContainer/VBoxContainer/NavRow/PrevButton
@onready var next_button : Button = $Control/PanelContainer/VBoxContainer/NavRow/NextButton
@onready var title_label: Label = $Control/PanelContainer/VBoxContainer/TabsContainer/TitleLabel
@onready var description_label: Label = $Control/PanelContainer/VBoxContainer/ScrollContainer2/DescriptionLabel
@onready var steps_container: VBoxContainer = $Control/PanelContainer/VBoxContainer/ScrollContainer/StepsContainer
@onready var pause_button : Button = $IconsContainer/PauseButton
@onready var control_button : Button = $IconsContainer/ControlButton
@onready var minimap_button: Button = $IconsContainer/MiniMapButton
@onready var inventory_button: Button = $IconsContainer/InventoryButton
@onready var icons_container : VBoxContainer = $IconsContainer
@onready var hud_menu_button : Button = $HudMenuButton

var current_index : int = 0
var hidden_by_pause : bool = false
var collapsed : bool = true
var game_started : bool = false
var menu_expanded : bool = false
var controls_hint_instance : CanvasLayer = null
var active_panel : String = ""
var hidden_by_story : bool = false

func _ready() -> void:
	steps_container.add_theme_constant_override( "separation", 1 )
	prev_button.pressed.connect( _on_prev_pressed )
	next_button.pressed.connect( _on_next_pressed )
	toggle_button.pressed.connect( _on_toggle_pressed )
	pause_button.pressed.connect( _on_pause_button_pressed )
	control_button.pressed.connect( _on_control_button_pressed )
	minimap_button.pressed.connect( _on_minimap_button_pressed )
	inventory_button.pressed.connect( _on_inventory_button_pressed )
	hud_menu_button.pressed.connect( _on_hud_menu_button_pressed )

	# A clicked button keeps its white focus box. Drop focus right after a press
	# so the box disappears from the menu icon and from every other HUD icon.
	for b : Button in [ hud_menu_button, toggle_button, pause_button, control_button, minimap_button, inventory_button ]:
		b.pressed.connect( b.release_focus )
	QuestManager.quest_updated.connect( _on_quest_updated )
	QuestManager.quest_started.connect( _on_quest_started )
	PauseMenu.shown.connect( _on_pause_shown )
	PauseMenu.hidden.connect( _on_pause_hidden )
	LevelManager.level_loaded.connect( _on_story_finished )

	hud_menu_button.visible = false
	icons_container.visible = false
	panel_container.visible = false

	show_quest( current_index )
	pass

func _on_inventory_button_pressed() -> void:
	PauseMenu.show_pause_menu()
	PauseMenu.open_inventory_tab()

func _on_hud_menu_button_pressed() -> void:
	menu_expanded = not menu_expanded
	icons_container.visible = menu_expanded and game_started and not hidden_by_pause

func hide_hud_menu() -> void:
	hidden_by_story = true
	hud_menu_button.visible = false
	icons_container.visible = false
	menu_expanded = false
	_update_panel_visibility()

func show_hud_menu() -> void:
	hidden_by_story = false
	if game_started:
		hud_menu_button.visible = true
	_update_panel_visibility()

func _close_panel( panel_name : String ) -> void:
	match panel_name:
		"quest":
			collapsed = true
			_update_panel_visibility()
		"controls":
			if is_instance_valid( controls_hint_instance ):
				controls_hint_instance.close()
		"minimap":
			MiniMapUI.force_close()

func _open_panel( panel_name : String ) -> void:
	match panel_name:
		"quest":
			collapsed = false
			_update_panel_visibility()
		"controls":
			# Still fading out from the last close: don't stack a second panel
			if is_instance_valid( controls_hint_instance ):
				return
			controls_hint_instance = CONTROLS_HINT.instantiate()
			get_tree().current_scene.add_child( controls_hint_instance )
			controls_hint_instance.closed.connect( _on_controls_hint_closed )
		"minimap":
			MiniMapUI.force_open()

func _toggle_panel( panel_name : String ) -> void:
	if active_panel == panel_name:
		_close_panel( panel_name )
		active_panel = ""
		return
	
	if active_panel != "":
		_close_panel( active_panel )
	
	_open_panel( panel_name )
	active_panel = panel_name

func _on_minimap_button_pressed() -> void:
	_toggle_panel( "minimap" )

func _on_story_finished() -> void:
	if get_tree().current_scene and get_tree().current_scene.name == "Main Menu":
		print("QuestView: level_loaded fired on Main Menu, ignoring")
		return
	print("QuestView: level loaded, showing hud button")
	game_started = true
	hud_menu_button.visible = true
	_update_panel_visibility()
	# SaveManager restores QuestManager.current_quests without emitting any
	# signal, so redraw the quest list here or it stays stale after a load.
	show_quest( current_index )

func _on_toggle_pressed() -> void:
	_toggle_panel( "quest" )

func _on_pause_button_pressed() -> void:
	PauseMenu.toggle_pause()

func _on_control_button_pressed() -> void:
	_toggle_panel( "controls" )

func _on_controls_hint_closed() -> void:
	controls_hint_instance = null
	if active_panel == "controls":
		active_panel = ""

func _on_pause_shown() -> void:
	hidden_by_pause = true
	icons_container.visible = false
	_update_panel_visibility()
	pass

func _on_pause_hidden() -> void:
	hidden_by_pause = false
	show_quest( current_index )
	pass

func _update_panel_visibility() -> void:
	panel_container.visible = game_started and not hidden_by_pause and not hidden_by_story and not collapsed

func _get_active_quests() -> Array:
	var _active : Array = []
	for q in QuestManager.current_quests:
		if q.is_complete == false:
			_active.append( q )
	return _active

func _on_quest_started( q ) -> void:
	var _active : Array = _get_active_quests()
	for i in _active.size():
		if _active[i].title == q.title:
			show_quest( i )
			break
	pass

func show_quest( index : int ) -> void:
	var _active : Array = _get_active_quests()
	
	if _active.size() == 0:
		panel_container.visible = false
		_clear_steps()
		return
	
	_update_panel_visibility()
	
	current_index = wrapi( index, 0, _active.size() )
	var q = _active[ current_index ]
	var quest_data : Quest = QuestManager.find_quest_by_title( q.title )
	if quest_data == null:
		return
	
	title_label.text = quest_data.title
	description_label.text = quest_data.description
	
	_clear_steps()
	for i in quest_data.steps.size():
		var step_name : String = quest_data.steps[i]
		var row := HBoxContainer.new()
		
		var is_complete : bool = q.completed_steps.has( step_name.to_lower() )

		var check_box : Control = _make_check_box( is_complete )
		row.add_child( check_box )
		
		var label := Label.new()
		_match_description_style( label )
		var target : int = 1
		if i < quest_data.step_targets.size():
			target = quest_data.step_targets[i]
		if target > 1:
			var current : int = q.get("step_counts", {}).get( step_name.to_lower(), 0 )
			label.text = step_name + " (" + str( current ) + "/" + str( target ) + ")"
		else:
			label.text = step_name
		row.add_child( label )
		
		steps_container.add_child( row )
	pass

# Builds one check box for a quest step, using the shared check box picture.
func _make_check_box( is_complete : bool ) -> Control:
	var tex : Texture2D = load( CHECKBOX_PATH ) as Texture2D
	if tex == null:
		push_warning( "QuestView: checkbox picture not found: " + CHECKBOX_PATH )
		return _make_plain_check_box( is_complete )

	var frame : Texture2D = tex
	var w : int = tex.get_width()
	var h : int = tex.get_height()

	if CHECKBOX_CHECKED_PATH != "":
		# Two separate pictures: the first is unchecked, the second is checked
		if is_complete:
			var checked_tex := load( CHECKBOX_CHECKED_PATH ) as Texture2D
			if checked_tex:
				frame = checked_tex
	elif w >= h * 2:
		# Two pictures side by side
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2( ( w / 2 ) if is_complete else 0, 0, w / 2, h )
		frame = atlas
	elif h >= w * 2:
		# Two pictures stacked
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2( 0, ( h / 2 ) if is_complete else 0, w, h / 2 )
		frame = atlas

	var rect := TextureRect.new()
	rect.texture = frame
	# The box is sized to match the step text, which matches the description
	var box_size : float = float( description_label.get_theme_font_size( "font_size" ) ) + CHECKBOX_EXTRA_SIZE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.custom_minimum_size = Vector2( box_size, box_size )
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect


# Gives a step label the same font, size and outline as the description text,
# so changing DescriptionLabel in the Inspector changes the steps too.
func _match_description_style( label : Label ) -> void:
	label.add_theme_font_size_override( "font_size", description_label.get_theme_font_size( "font_size" ) )
	var f : Font = description_label.get_theme_font( "font" )
	if f:
		label.add_theme_font_override( "font", f )
	label.add_theme_color_override( "font_color", description_label.get_theme_color( "font_color" ) )
	label.add_theme_color_override( "font_outline_color", description_label.get_theme_color( "font_outline_color" ) )
	label.add_theme_constant_override( "outline_size", description_label.get_theme_constant( "outline_size" ) )
	label.add_theme_constant_override( "line_spacing", description_label.get_theme_constant( "line_spacing" ) )


# The old plain box, only used if the picture cannot be loaded
func _make_plain_check_box( is_complete : bool ) -> Control:
	var check_box := Panel.new()
	check_box.custom_minimum_size = Vector2(14, 14)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.15, 0.85, 0.3) if is_complete else Color(0.2, 0.2, 0.2)
	box_style.border_color = Color(1, 1, 1, 0.9)
	box_style.set_border_width_all( 1 )
	box_style.set_corner_radius_all( 1 )
	check_box.add_theme_stylebox_override( "panel", box_style )
	return check_box


func _clear_steps() -> void:
	for c in steps_container.get_children():
		c.queue_free()
	pass

func _on_prev_pressed() -> void:
	show_quest( current_index - 1 )

func _on_next_pressed() -> void:
	show_quest( current_index + 1 )

func _on_quest_updated( _q ) -> void:
	show_quest( current_index )
	pass

func get_selected_quest_title() -> String:
	var _active : Array = _get_active_quests()
	if _active.size() == 0:
		return ""
	return _active[ wrapi( current_index, 0, _active.size() ) ].title
