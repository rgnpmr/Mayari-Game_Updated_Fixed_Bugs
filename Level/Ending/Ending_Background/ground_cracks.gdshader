shader_type canvas_item;

// 0 = no cracks, 1 = fully cracked
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Set by the script, you don't need to touch these two
uniform vec2 aspect = vec2(1.78, 1.0);
uniform vec2 pixels = vec2(285.0, 160.0);

// How many crack cells fit across the map's height. Higher = more, smaller cracks.
uniform float cell_scale : hint_range(2.0, 20.0) = 6.0;
// How crooked the cracks are
uniform float jaggedness : hint_range(0.0, 1.5) = 0.6;
// How thick the cracks get at the end
uniform float crack_width : hint_range(0.01, 0.15) = 0.05;
uniform vec4 crack_color : source_color = vec4(0.42, 0.29, 0.18, 0.9);
uniform vec4 rim_color : source_color = vec4(0.71, 0.54, 0.33, 0.4);

vec2 hash22(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// Chunky pixels so it matches your pixel art
	vec2 uv = floor(UV * pixels) / pixels;
	vec2 p = uv * aspect * cell_scale;

	// Bend the lines so they look broken, not straight
	p += (vec2(vnoise(p * 3.0), vnoise(p * 3.0 + 17.0)) - 0.5) * jaggedness;

	vec2 g = floor(p);
	vec2 f = fract(p);

	float d1 = 8.0;
	float d2 = 8.0;
	vec2 id1 = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 r = o + hash22(g + o) - f;
			float d = dot(r, r);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id1 = g + o;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}

	// Distance to the line between two cells
	float edge = sqrt(d2) - sqrt(d1);

	// Each patch starts cracking at its own moment as progress grows
	float shown = step(hash12(id1), progress);
	float w = crack_width * (0.35 + 0.65 * progress);

	float core = step(edge, w) * shown;
	float rim = step(edge, w * 1.8) * shown;

	vec4 col = vec4(0.0);
	col = mix(col, rim_color, rim);
	col = mix(col, crack_color, core);
	COLOR = col;
}