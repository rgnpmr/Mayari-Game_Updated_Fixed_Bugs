extends CanvasLayer

const SIZE := 44.0

const JOY_RADIUS := 40.0     # how far the knob can move from the center
const JOY_ZONE := 75.0       # how close to the joystick a touch must start to grab it
const JOY_DEADZONE := 0.2    # ignore tiny movements near the center

# Look of the pad
const PAD_DIAMETER := 100.0
const KNOB_DIAMETER := 36.0
const TEX_SCALE := 3.0       # pictures are drawn 3x bigger and scaled down so they stay sharp
const COL_PAD := Color(0.34, 0.38, 0.38, 0.8)
const COL_ARROW := Color(0.22, 0.26, 0.27, 0.95)
const COL_KNOB := Color(0.49, 0.55, 0.55, 0.92)
const COL_KNOB_PRESSED := Color(0.62, 0.69, 0.69, 0.98)
const COL_LETTER := Color(0.16, 0.19, 0.2, 1.0)

# Hide the controls in any scene whose file path contains one of these words
const HIDE_IN_SCENES := ["main_menu", "intro_storytelling", "story_scene_chapter_2", "story_scene_chapter_2_1", "story_scene_restore_forest_quest", "ending_dialogue", "ending_calm", "ending_catastrophe", "loading_screen"]
# Scenes where tapping the screen counts as pressing Space
const TAP_TO_CONTINUE_SCENES := ["intro_storytelling", "story_scene_chapter_2", "story_scene_chapter_2_1", "story_scene_restore_forest_quest", "ending_dialogue", "ending_calm", "ending_catastrophe"]
# Set to true to see the controls on your laptop while testing
const DEBUG_SHOW_ON_PC := false

var is_mobile := false

# other scripts can set this to true to hide the controls temporarily
var suppressed := false

var joy_center := Vector2.ZERO
var joy_index := -1          # which finger is holding the joystick (-1 = none)
var joy_knob: Sprite2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keeps working while dialogue pauses the game
	layer = 100
	is_mobile = DEBUG_SHOW_ON_PC or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	visible = false
	if not is_mobile:
		return

	var vp: Vector2 = get_viewport().get_visible_rect().size

	# Joystick (bottom-left)
	joy_center = Vector2(85, vp.y - 80)
	var base := Sprite2D.new()
	base.texture = _pad_texture(PAD_DIAMETER)
	base.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	base.scale = Vector2.ONE / TEX_SCALE
	base.position = joy_center
	add_child(base)

	joy_knob = Sprite2D.new()
	joy_knob.texture = _disc_texture(KNOB_DIAMETER, COL_KNOB, COL_KNOB, 0.0)
	joy_knob.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	joy_knob.scale = Vector2.ONE / TEX_SCALE
	joy_knob.position = joy_center
	add_child(joy_knob)

	# Interact (bottom-right)
	_make_button("interact", "I", Vector2(vp.x - 50, vp.y - 60), 52.0)

	# Let go of the stick whenever a new level starts loading
	call_deferred("_connect_level_signals")


func _connect_level_signals() -> void:
	var lm := get_node_or_null("/root/LevelManager")
	if lm == null:
		return
	if lm.has_signal("level_load_started") and not lm.level_load_started.is_connected( _on_level_changing ):
		lm.level_load_started.connect( _on_level_changing )
	if lm.has_signal("level_loaded") and not lm.level_loaded.is_connected( _on_level_changing ):
		lm.level_loaded.connect( _on_level_changing )


func _on_level_changing() -> void:
	if is_mobile:
		_reset_joystick()


# The app loses focus or goes to the background: all fingers are gone
func _notification(what: int) -> void:
	if not is_mobile:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_reset_joystick()


func _make_button(action: String, symbol: String, center: Vector2, size: float = SIZE) -> void:
	var btn := TouchScreenButton.new()
	btn.action = action
	btn.passby_press = true
	btn.texture_normal = _disc_texture(size, COL_PAD, COL_KNOB, 0.62)
	btn.texture_pressed = _disc_texture(size, COL_PAD, COL_KNOB_PRESSED, 0.62)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	btn.scale = Vector2.ONE / TEX_SCALE

	var shape := RectangleShape2D.new()
	shape.size = Vector2(size, size) * TEX_SCALE
	btn.shape = shape
	btn.shape_visible = false
	btn.position = center - Vector2(size, size) / 2.0

	var label := Label.new()
	label.text = symbol
	label.size = Vector2(size, size) * TEX_SCALE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", int(size * 0.4 * TEX_SCALE))
	label.add_theme_color_override("font_color", COL_LETTER)
	btn.add_child(label)

	add_child(btn)


# A round pad with four small arrows (up, right, down, left)
func _pad_texture(diameter: float) -> ImageTexture:
	var px := int(diameter * TEX_SCALE)
	var img := Image.create_empty(px, px, false, Image.FORMAT_RGBA8)
	var c := Vector2(px, px) / 2.0
	var r := px / 2.0

	var dist := r * 0.64
	var half_w := r * 0.085
	var h := r * 0.10
	var arrows : Array = []
	for k in 4:
		var dir := Vector2.RIGHT.rotated(k * PI / 2.0)
		var side := dir.rotated(PI / 2.0)
		arrows.append([
			c + dir * (dist + h / 2.0),
			c + dir * (dist - h / 2.0) + side * half_w,
			c + dir * (dist - h / 2.0) - side * half_w,
		])

	for y in px:
		for x in px:
			var p := Vector2(x + 0.5, y + 0.5)
			var a := clampf(r - p.distance_to(c), 0.0, 1.0)
			if a <= 0.0:
				continue
			var col := COL_PAD
			for t in arrows:
				if _in_triangle(p, t[0], t[1], t[2]):
					col = COL_ARROW
					break
			img.set_pixel(x, y, Color(col.r, col.g, col.b, col.a * a))
	return ImageTexture.create_from_image(img)


# A round disc, with an optional lighter circle inside it (inner_ratio 0 = none)
func _disc_texture(diameter: float, outer: Color, inner: Color, inner_ratio: float) -> ImageTexture:
	var px := int(diameter * TEX_SCALE)
	var img := Image.create_empty(px, px, false, Image.FORMAT_RGBA8)
	var c := Vector2(px, px) / 2.0
	var r := px / 2.0
	var inner_r := r * inner_ratio
	for y in px:
		for x in px:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var a := clampf(r - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var col := outer
			if inner_ratio > 0.0:
				col = outer.lerp(inner, clampf(inner_r - d, 0.0, 1.0))
			img.set_pixel(x, y, Color(col.r, col.g, col.b, col.a * a))
	return ImageTexture.create_from_image(img)


func _in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var d1 := _tri_sign(p, a, b)
	var d2 := _tri_sign(p, b, c)
	var d3 := _tri_sign(p, c, a)
	var has_neg := d1 < 0.0 or d2 < 0.0 or d3 < 0.0
	var has_pos := d1 > 0.0 or d2 > 0.0 or d3 > 0.0
	return not (has_neg and has_pos)


func _tri_sign(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y)


# True when a story scene has been added on top of the current level
func _story_scene_on_top() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	for child in scene.get_children():
		if child.has_signal("story_finished") or child.name.begins_with("StoryScene"):
			return true
	return false


# True when the current scene is one of the listed scene files
func _scene_matches(keys: Array) -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var path := scene.scene_file_path.to_lower()
	for key in keys:
		if path.contains(key):
			return true
	return false


func _input(event: InputEvent) -> void:
	if not is_mobile:
		return

	# Joystick. Letting go and dragging are always handled, even while the controls
	# are hidden, so a finger lifted during a scene change can never leave the stick stuck.
	if event is InputEventScreenTouch:
		if event.pressed:
			if visible and joy_index == -1 and event.position.distance_to(joy_center) <= JOY_ZONE:
				joy_index = event.index
				_update_stick(event.position)
		elif event.index == joy_index:
			_reset_joystick()
	elif event is InputEventScreenDrag and event.index == joy_index:
		_update_stick(event.position)

	# Tapping the screen in story scenes acts like pressing Space
	if not (event is InputEventScreenTouch and event.pressed):
		return
	# While choice buttons are showing, a tap must not act like Space
	if get_tree().get_first_node_in_group( "choosing" ) != null:
		return
	if _scene_matches(TAP_TO_CONTINUE_SCENES) or _story_scene_on_top():
		_send_space()


func _update_stick(pos: Vector2) -> void:
	var offset := pos - joy_center
	if offset.length() > JOY_RADIUS:
		offset = offset.normalized() * JOY_RADIUS
	joy_knob.position = joy_center + offset

	var v := offset / JOY_RADIUS
	if v.length() < JOY_DEADZONE:
		v = Vector2.ZERO

	_set_action("left", maxf(-v.x, 0.0))
	_set_action("right", maxf(v.x, 0.0))
	_set_action("up", maxf(-v.y, 0.0))
	_set_action("down", maxf(v.y, 0.0))


func _set_action(action_name: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)


func _reset_joystick() -> void:
	joy_index = -1
	if joy_knob:
		joy_knob.position = joy_center
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("up")
	Input.action_release("down")


func _send_space() -> void:
	var down := InputEventKey.new()
	down.keycode = KEY_SPACE
	down.physical_keycode = KEY_SPACE
	down.pressed = true
	Input.parse_input_event(down)

	var up := InputEventKey.new()
	up.keycode = KEY_SPACE
	up.physical_keycode = KEY_SPACE
	up.pressed = false
	Input.parse_input_event(up)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		# the scene is being swapped: let go of the stick here too
		visible = false
		if joy_index != -1:
			_reset_joystick()
		return
	var hide_here := _scene_matches(HIDE_IN_SCENES) or _story_scene_on_top()
	visible = is_mobile and not hide_here and not suppressed

	# if the controls get hidden (dialogue, cutscene) while the stick is held, let go
	if not visible and joy_index != -1:
		_reset_joystick()
