shader_type canvas_item;

uniform float sway_speed : hint_range(0.0, 5.0) = 1.0;
uniform float sway_strength : hint_range(0.0, 50.0) = 8.0;
uniform float sway_offset : hint_range(0.0, 6.28) = 0.0;
uniform float sway_start : hint_range(0.0, 1.0) = 0.5; // UV.y below this = no sway at all

void vertex() {
	float height_factor = 1.0 - UV.y;

	// only apply sway above the threshold, trunk stays fully rigid below it
	float sway_mask = smoothstep( 1.0 - sway_start, 1.0, height_factor );

	float sway = sin( TIME * sway_speed + sway_offset ) * sway_strength * sway_mask;

	VERTEX.x += sway;
}