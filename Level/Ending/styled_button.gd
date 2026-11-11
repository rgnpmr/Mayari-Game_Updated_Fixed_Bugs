class_name StyledButton extends Button
## One simple button style shared by the main menu and the ending scene.
## Use it directly (attach this script to a Button), or write
## "extends StyledButton" in a button script that has its own click logic.
## All colors and sizes can be changed in the Inspector.

@export_group("Colors")
## Dark translucent panel with a cream border and a gold hover
@export var bg_color : Color = Color(0.05, 0.09, 0.06, 0.8)
@export var border_color : Color = Color(0.95, 0.92, 0.8)
@export var hover_bg_color : Color = Color(0.597, 0.463, 0.161, 0.95)
@export var pressed_bg_color : Color = Color(0.35, 0.27, 0.09, 0.95)
@export var disabled_bg_color : Color = Color(0.05, 0.09, 0.06, 0.45)
@export var text_color : Color = Color(0.95, 0.92, 0.8)
@export var hover_text_color : Color = Color.WHITE
@export var disabled_text_color : Color = Color(0.7, 0.7, 0.65, 0.5)
@export var text_outline_color : Color = Color.BLACK
@export var shadow_color : Color = Color(0.0, 0.0, 0.0, 0.0)

@export_group("Shape")
## These are in game pixels, so they look bigger once the game is scaled up.
@export var border_width : int = 1
@export var corner_radius : int = 2
@export var padding : Vector2 = Vector2(14, 5)
@export var min_button_size : Vector2 = Vector2(72, 22)
## 0 keeps the font size from your theme
@export var font_size : int = 0
@export var text_outline_size : int = 1
## Outline shown when the button is selected with keyboard or gamepad
@export var show_focus_ring : bool = false

@export_group("Hover")
@export var hover_scale : float = 1.08

var _styled : bool = false
var _tween : Tween


func _ready() -> void:
	apply_style()


# Safe to call more than once, so a child script can call it too
func apply_style() -> void:
	if _styled:
		return
	_styled = true

	custom_minimum_size = custom_minimum_size.max( min_button_size )
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# The old picture-button settings would hide the style, so turn them off
	flat = false
	icon = null

	add_theme_stylebox_override( "normal", _make_box( bg_color, border_color ) )
	add_theme_stylebox_override( "hover", _make_box( hover_bg_color, border_color ) )
	add_theme_stylebox_override( "pressed", _make_box( pressed_bg_color, border_color ) )
	add_theme_stylebox_override( "hover_pressed", _make_box( pressed_bg_color, border_color ) )
	add_theme_stylebox_override( "disabled", _make_box( disabled_bg_color, border_color.darkened( 0.2 ) ) )
	if show_focus_ring:
		add_theme_stylebox_override( "focus", _make_focus_box() )
	else:
		add_theme_stylebox_override( "focus", StyleBoxEmpty.new() )

	add_theme_color_override( "font_color", text_color )
	add_theme_color_override( "font_focus_color", hover_text_color )
	add_theme_color_override( "font_hover_color", hover_text_color )
	add_theme_color_override( "font_pressed_color", hover_text_color )
	add_theme_color_override( "font_hover_pressed_color", hover_text_color )
	add_theme_color_override( "font_disabled_color", disabled_text_color )
	add_theme_color_override( "font_outline_color", text_outline_color )
	add_theme_constant_override( "outline_size", text_outline_size )
	if font_size > 0:
		add_theme_font_size_override( "font_size", font_size )

	# Scale from the middle of the button, and keep that true if it resizes
	pivot_offset = size / 2.0
	resized.connect( func(): pivot_offset = size / 2.0 )

	mouse_entered.connect( _on_hover_start )
	mouse_exited.connect( _on_hover_end )
	focus_entered.connect( _on_hover_start )
	focus_exited.connect( _on_hover_end )


func _make_box( bg : Color, border : Color ) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all( border_width )
	box.set_corner_radius_all( corner_radius )
	box.content_margin_left = padding.x
	box.content_margin_right = padding.x
	box.content_margin_top = padding.y
	box.content_margin_bottom = padding.y
	box.anti_aliasing = false  # keeps the corners crisp and pixel-like
	box.shadow_color = shadow_color
	box.shadow_size = 1
	box.shadow_offset = Vector2( 0, 1 )
	return box


func _make_focus_box() -> StyleBoxFlat:
	var box := _make_box( Color(0, 0, 0, 0), Color.WHITE )
	box.set_border_width_all( border_width + 1 )
	box.shadow_color = Color(0, 0, 0, 0)
	return box


func _scale_to( target : Vector2 ) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property( self, "scale", target, 0.1 )


func _on_hover_start() -> void:
	if disabled:
		return
	_scale_to( Vector2.ONE * hover_scale )


func _on_hover_end() -> void:
	_scale_to( Vector2.ONE )
