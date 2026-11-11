shader_type canvas_item;

uniform float sway_speed : hint_range(0.0, 5.0) = 1.5;
uniform float sway_strength : hint_range(0.0, 10.0) = 2.0; // in pixels

void fragment() {
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;
	float sway_factor = 1.0 - UV.y; // top of sprite = full sway, bottom = anchored
	float offset_pixels = sin(TIME * sway_speed) * sway_strength * sway_factor;
	offset_pixels = floor( offset_pixels + 0.5 ); // snap to whole pixels, avoids shimmer
	vec2 offset_uv = vec2( offset_pixels * pixel_size.x, 0.0 );
	COLOR = texture( TEXTURE, UV - offset_uv );
}