shader_type canvas_item;
render_mode blend_mix;

group_uniforms Sprite;
uniform bool keep_sprite_color = true;
uniform vec4 fill_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_mix : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.35;

group_uniforms Outline;
uniform vec4 outline_color : source_color = vec4(0.02, 0.07, 0.09, 1.0);
uniform float outline_size : hint_range(0.0, 8.0) = 1.6;
uniform float outline_softness : hint_range(0.0, 2.0) = 1.0;

group_uniforms Shadow;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.035, 0.04, 0.78);
uniform vec2 shadow_offset = vec2(2.0, 3.0);
uniform float shadow_depth : hint_range(0.0, 8.0) = 3.0;
uniform vec2 shadow_depth_offset = vec2(1.0, 1.0);
uniform float shadow_step : hint_range(0.25, 3.0) = 1.0;
uniform float shadow_spread : hint_range(0.0, 4.0) = 1.0;
uniform float shadow_alpha_decay : hint_range(0.0, 1.0) = 0.8;

group_uniforms Highlight;
uniform vec4 top_highlight : source_color = vec4(1.0, 1.0, 1.0, 0.12);
uniform float highlight_cutoff : hint_range(0.0, 1.0) = 0.28;

float uv_bounds(vec2 uv) {
	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	return inside.x * inside.y;
}

float sample_alpha(vec2 uv) {
	vec2 clamped = clamp(uv, vec2(0.0), vec2(1.0));
	return texture(TEXTURE, clamped).a * uv_bounds(uv);
}

float max_alpha_8(vec2 uv, vec2 px) {
	float a = 0.0;
	a = max(a, sample_alpha(uv + vec2(px.x, 0.0)));
	a = max(a, sample_alpha(uv + vec2(-px.x, 0.0)));
	a = max(a, sample_alpha(uv + vec2(0.0, px.y)));
	a = max(a, sample_alpha(uv + vec2(0.0, -px.y)));
	a = max(a, sample_alpha(uv + vec2(px.x, px.y)));
	a = max(a, sample_alpha(uv + vec2(-px.x, px.y)));
	a = max(a, sample_alpha(uv + vec2(px.x, -px.y)));
	a = max(a, sample_alpha(uv + vec2(-px.x, -px.y)));
	return a;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float base_alpha = step(alpha_cutoff, tex.a);

	vec2 outline_px = TEXTURE_PIXEL_SIZE * outline_size * max(outline_softness, 0.0001);
	float outline_sample = max_alpha_8(UV, outline_px);
	float outline_alpha = max(outline_sample - base_alpha, 0.0);

	vec2 base_shadow_offset = shadow_offset * TEXTURE_PIXEL_SIZE;
	vec2 depth_direction = shadow_depth_offset * shadow_step * TEXTURE_PIXEL_SIZE;
	vec2 shadow_px = TEXTURE_PIXEL_SIZE * shadow_spread;
	float shadow_alpha = 0.0;
	float layer_alpha = 1.0;

	for (int i = 1; i <= 8; i++) {
		float layer = float(i);
		if (layer <= shadow_depth) {
			vec2 shadow_uv = UV - base_shadow_offset - depth_direction * layer;
			float shadow_sample = sample_alpha(shadow_uv);
			shadow_alpha = max(shadow_alpha, step(alpha_cutoff, shadow_sample) * layer_alpha);
			layer_alpha *= shadow_alpha_decay;
		}
	}

	vec3 body_rgb = tex.rgb;
	if (!keep_sprite_color) {
		body_rgb = fill_tint.rgb;
	}
	body_rgb = mix(body_rgb, fill_tint.rgb, tint_mix);
	float highlight = smoothstep(highlight_cutoff, 0.0, UV.y);
	body_rgb = mix(body_rgb, top_highlight.rgb, top_highlight.a * highlight);

	vec4 shadow = vec4(shadow_color.rgb, shadow_color.a * shadow_alpha);
	vec4 outline = vec4(outline_color.rgb, outline_color.a * outline_alpha);
	vec4 body = vec4(body_rgb, tex.a);

	vec4 result = shadow;
	result.rgb = mix(result.rgb, outline.rgb, outline.a);
	result.a = max(result.a, outline.a);
	result.rgb = mix(result.rgb, body.rgb, body.a);
	result.a = max(result.a, body.a);

	COLOR = result;
}
