shader_type canvas_item;
// Water shimmer for a TileMapLayer.
// Light streaks and a few darker ripples drift across the water in whole-pixel
// steps, so it keeps the pixel-art look. Nothing is stretched or warped, so
// tiles never bleed into their neighbours. Only blue pixels are affected, so
// shore tiles and lily pads on the same layer stay as they are.

group_uniforms flow;
uniform vec2 flow_direction = vec2(0.0, 1.0);   // (0,1) = down the river, (1,0) = to the right
uniform float flow_speed = 6.0;                 // pixels per second

group_uniforms look;
uniform vec4 highlight_color : source_color = vec4(0.85, 0.95, 1.0, 1.0);
uniform vec4 shade_color : source_color = vec4(0.05, 0.25, 0.5, 1.0);
uniform float highlight_amount : hint_range(0.0, 1.0) = 0.35;
uniform float shade_amount : hint_range(0.0, 1.0) = 0.25;
// Higher = fewer highlights. Lower shade threshold = fewer dark ripples.
uniform float highlight_threshold : hint_range(0.5, 0.95) = 0.68;
uniform float shade_threshold : hint_range(0.05, 0.5) = 0.30;

group_uniforms pattern;
uniform float cell_size = 3.0;                  // size of the streaks, in pixels
uniform float streak_stretch = 4.0;             // how much longer streaks are sideways

varying vec2 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void vertex() {
	// World position, so the pattern stays fixed to the map and not the screen
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 c = COLOR;
	
	// Blue pixels only: skips lily pads (green) and shore (brown)
	float water = step(0.15, c.b - c.r) * step(c.g, c.b);
	
	// Snap to whole pixels, then drift the pattern along the flow direction
	vec2 p = floor(world_pos - normalize(flow_direction) * TIME * flow_speed);
	vec2 q = vec2(p.x / (cell_size * streak_stretch), p.y / cell_size);
	float n = noise(q);
	
	float hl = step(highlight_threshold, n);
	float sh = step(n, shade_threshold);
	
	vec3 col = mix(c.rgb, highlight_color.rgb, hl * highlight_amount * water);
	col = mix(col, shade_color.rgb, sh * shade_amount * water);
	COLOR = vec4(col, c.a);
}