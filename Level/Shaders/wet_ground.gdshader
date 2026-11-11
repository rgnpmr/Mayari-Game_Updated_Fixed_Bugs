shader_type canvas_item;

uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float sheen_speed : hint_range(0.0, 5.0) = 0.5;
uniform float sheen_density : hint_range(0.001, 1.0) = 0.15;
uniform float darken_amount : hint_range(0.0, 1.0) = 0.15;
uniform float glint_threshold : hint_range(0.8, 0.999) = 0.9;
uniform float glint_min_size : hint_range(0.01, 0.5) = 0.15;
uniform float glint_max_size : hint_range(0.01, 0.5) = 0.35;
uniform vec3 glint_tint : source_color = vec3(0.8, 0.9, 1.0);
uniform vec3 modulate_compensation : source_color = vec3(1.0, 1.0, 1.0);

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(269.5, 183.3))) * 24634.6345);
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	vec3 darkened = mix( tex_color.rgb, tex_color.rgb * (1.0 - darken_amount), wetness );

	vec2 scaled_pos = world_pos * sheen_density;
	vec2 cell = floor(scaled_pos);
	vec2 local_uv = fract(scaled_pos);

	float n = hash(cell);
	float size_variation = hash2(cell);

	float dist_to_center = distance(local_uv, vec2(0.5));
	float glint_radius = mix(glint_min_size, glint_max_size, size_variation);
	float glint_shape = 1.0 - smoothstep(glint_radius * 0.3, glint_radius, dist_to_center);

	float is_active = step(glint_threshold, n);
	float flicker = sin(TIME * sheen_speed + n * 100.0) * 0.5 + 0.5;
	float brightness = mix(0.1, 0.35, size_variation);

	float glint = is_active * glint_shape * flicker * wetness * brightness;

	vec3 compensated_tint = glint_tint * modulate_compensation;
	vec3 final_color = darkened + compensated_tint * glint;
	COLOR = vec4( final_color, tex_color.a );
}