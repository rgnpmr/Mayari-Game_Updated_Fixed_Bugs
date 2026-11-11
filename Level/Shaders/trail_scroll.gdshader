shader_type canvas_item;

uniform float scroll_speed : hint_range(0.0, 5.0) = 1.0;
uniform float tile_spacing : hint_range(0.05, 10.0) = 0.3;

void fragment() {
	float offset = TIME * scroll_speed;

	vec2 scrolled_uv = UV;
	scrolled_uv.x = fract( (UV.x * tile_spacing) - offset );
	COLOR = texture( TEXTURE, scrolled_uv );
}