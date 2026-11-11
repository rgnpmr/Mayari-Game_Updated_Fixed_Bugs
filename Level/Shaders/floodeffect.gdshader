shader_type canvas_item;

uniform float water_level : hint_range(0.0, 1.0) = 0.0;
uniform vec4 water_color : source_color = vec4(0.1, 0.35, 0.55, 0.75);
uniform vec4 foam_color : source_color = vec4(0.8, 0.95, 1.0, 0.9);
uniform float wave_amp : hint_range(0.0, 0.05) = 0.012;
uniform float wave_freq : hint_range(1.0, 60.0) = 18.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.2;
uniform float foam_thickness : hint_range(0.0, 0.05) = 0.01;

void fragment() {
	float wave = sin(UV.x * wave_freq + TIME * wave_speed) * wave_amp;
	float surface = water_level + wave;

	if (UV.y < surface) {
		float dist_from_surface = surface - UV.y;
		if (dist_from_surface < foam_thickness) {
			COLOR = foam_color;
		} else {
			COLOR = water_color;
		}
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}