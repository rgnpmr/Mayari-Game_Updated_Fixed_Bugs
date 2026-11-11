shader_type canvas_item;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	
	vec4 tex_color = texture(TEXTURE, UV);
	
	if (dist > 0.5) {
		discard;
	}
	
	COLOR = tex_color;
}