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
	float alpha = step(alpha_cutoff, base.a);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_size;
	vec2 sample_uv = UV;
	vec2 inside = vec2(0.0);

	float outline_alpha = 0.0;
	sample_uv = UV + vec2(px.x, 0.0);
	inside = step(vec2(0.0), sample_uv) * step(sample_uv, vec2(1.0));
	outline_alpha = max(outline_alpha, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a * inside.x * inside.y);
	sample_uv = UV + vec2(-px.x, 0.0);
	inside = step(vec2(0.0), sample_uv) * step(sample_uv, vec2(1.0));
	outline_alpha = max(outline_alpha, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a * inside.x * inside.y);
	sample_uv = UV + vec2(0.0, px.y);
	inside = step(vec2(0.0), sample_uv) * step(sample_uv, vec2(1.0));
	outline_alpha = max(outline_alpha, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a * inside.x * inside.y);
	sample_uv = UV + vec2(0.0, -px.y);
	inside = step(vec2(0.0), sample_uv) * step(sample_uv, vec2(1.0));
	outline_alpha = max(outline_alpha, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a * inside.x * inside.y);
	sample_uv = UV + vec2(px.x, px.y);
	inside = step(vec2(0.0), sample_uv) * step(sample_uv, vec2(1.0));
	outline_alpha = max(outline_alpha, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a * inside.x * inside.y);
	sample_uv = UV + vec2(-px.x, px.y);
	inside = step(vec2(0.0), sample_uv) * step(sample_uv, vec2(1.0));
	outline_alpha = max(outline_alpha, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a * inside.x * inside.y);
	sample_uv = UV + vec2(px.x, -px.y);
	inside = step(vec2(0.0), sample_uv) * step(sample_uv, vec2(1.0));
	outline_alpha = max(outline_alpha, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a * inside.x * inside.y);
	sample_uv = UV + vec2(-px.x, -px.y);
	inside = step(vec2(0.0), sample_uv) * step(sample_uv, vec2(1.0));
	outline_alpha = max(outline_alpha, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a * inside.x * inside.y);
	outline_alpha = max(outline_alpha - alpha, 0.0);

	float blink = step(0.42, fract(TIME * blink_speed));
	float select_mix = select_strength * blink;
	vec4 outline = mix(hover_outline_color, select_outline_color, select_mix);
	float outline_strength = max(hover_strength, select_mix);

	vec4 result = base;
	if (outline_alpha > 0.0 && outline_strength > 0.0) {
		result.rgb = mix(result.rgb, outline.rgb, outline.a * outline_strength);
		result.a = max(result.a, outline_alpha * outline.a * outline_strength);
	}

	COLOR = result;
}
