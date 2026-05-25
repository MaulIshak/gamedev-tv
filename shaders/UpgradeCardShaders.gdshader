shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 hover_outline_color : source_color = vec4(0.35, 0.95, 1.0, 1.0);
uniform vec4 select_outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float outline_size : hint_range(0.0, 8.0) = 2.0;
uniform float hover_strength : hint_range(0.0, 1.0) = 0.0;
uniform float select_strength : hint_range(0.0, 1.0) = 0.0;
uniform float blink_speed : hint_range(1.0, 24.0) = 12.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;

	float current_alpha = step(alpha_cutoff, base.a);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_size;

	float neighbor_min = 1.0;

	neighbor_min = min(neighbor_min, texture(TEXTURE, clamp(UV + vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).a);
	neighbor_min = min(neighbor_min, texture(TEXTURE, clamp(UV + vec2(-px.x, 0.0), vec2(0.0), vec2(1.0))).a);
	neighbor_min = min(neighbor_min, texture(TEXTURE, clamp(UV + vec2(0.0, px.y), vec2(0.0), vec2(1.0))).a);
	neighbor_min = min(neighbor_min, texture(TEXTURE, clamp(UV + vec2(0.0, -px.y), vec2(0.0), vec2(1.0))).a);

	neighbor_min = min(neighbor_min, texture(TEXTURE, clamp(UV + vec2(px.x, px.y), vec2(0.0), vec2(1.0))).a);
	neighbor_min = min(neighbor_min, texture(TEXTURE, clamp(UV + vec2(-px.x, px.y), vec2(0.0), vec2(1.0))).a);
	neighbor_min = min(neighbor_min, texture(TEXTURE, clamp(UV + vec2(px.x, -px.y), vec2(0.0), vec2(1.0))).a);
	neighbor_min = min(neighbor_min, texture(TEXTURE, clamp(UV + vec2(-px.x, -px.y), vec2(0.0), vec2(1.0))).a);

	float near_transparent = 1.0 - step(alpha_cutoff, neighbor_min);

	// Outline digambar di dalam pixel kartu yang dekat area transparan
	float outline_alpha = current_alpha * near_transparent;

	float blink = step(0.42, fract(TIME * blink_speed));
	float select_mix = select_strength * blink;

	vec4 outline_color = mix(hover_outline_color, select_outline_color, select_mix);
	float outline_strength = max(hover_strength, select_mix);

	vec4 result = base;

	if (outline_alpha > 0.0 && outline_strength > 0.0) {
		result.rgb = mix(result.rgb, outline_color.rgb, outline_color.a * outline_strength);
		result.a = max(result.a, base.a);
	}

	COLOR = result;
}