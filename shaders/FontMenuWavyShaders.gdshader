shader_type canvas_item;
render_mode blend_mix;

group_uniforms Text;
uniform vec4 fill_color : source_color = vec4(1.0, 0.92, 0.18, 1.0);
uniform float fill_strength : hint_range(0.0, 2.0) = 1.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.45;

group_uniforms Outline;
uniform vec4 outline_color : source_color = vec4(0.015, 0.018, 0.022, 1.0);
uniform float outline_size : hint_range(0.0, 6.0) = 2.0;

group_uniforms Shadow;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.96);
uniform vec2 shadow_offset = vec2(1.5, 2.25);
uniform float shadow_depth : hint_range(0.0, 8.0) = 4.0;
uniform vec2 shadow_depth_offset = vec2(1.0, 1.35);
uniform float shadow_step : hint_range(0.25, 3.0) = 1.0;
uniform float shadow_spread : hint_range(0.0, 4.0) = 1.0;
uniform float shadow_alpha_decay : hint_range(0.0, 1.0) = 0.92;

group_uniforms Highlight;
uniform vec4 top_highlight : source_color = vec4(1.0, 1.0, 1.0, 0.14);
uniform float highlight_cutoff : hint_range(0.0, 1.0) = 0.46;

group_uniforms Wave;
uniform bool enable_wave = true;
uniform float wave_amplitude : hint_range(0.0, 12.0) = 2.25;
uniform float wave_frequency : hint_range(0.001, 0.2) = 0.045;
uniform float wave_speed : hint_range(0.0, 6.0) = 0.7;
uniform float wave_phase : hint_range(0.0, 6.28318) = 0.0;

group_uniforms;

float uv_bounds(vec2 uv) {
	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	return inside.x * inside.y;
}

void vertex() {
	if (enable_wave) {
		float wave = sin((VERTEX.x * wave_frequency) + (TIME * wave_speed) + wave_phase);
		VERTEX.y += wave * wave_amplitude;
	}
}

void fragment() {
	float text_alpha = step(alpha_cutoff, texture(TEXTURE, UV).a);

	vec2 outline_px = TEXTURE_PIXEL_SIZE * outline_size;
	vec2 outline_inner_px = TEXTURE_PIXEL_SIZE * outline_size * 0.5;
	float outline_sample = text_alpha;
	vec2 sample_uv = UV + vec2(outline_px.x, 0.0);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(-outline_px.x, 0.0);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(0.0, outline_px.y);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(0.0, -outline_px.y);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(outline_px.x, outline_px.y);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(-outline_px.x, outline_px.y);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(outline_px.x, -outline_px.y);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(-outline_px.x, -outline_px.y);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(outline_inner_px.x, 0.0);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(-outline_inner_px.x, 0.0);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(0.0, outline_inner_px.y);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	sample_uv = UV + vec2(0.0, -outline_inner_px.y);
	outline_sample = max(outline_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
	float outline_alpha = max(outline_sample - text_alpha, 0.0);

	vec2 base_shadow_offset = shadow_offset * TEXTURE_PIXEL_SIZE;
	vec2 depth_direction = shadow_depth_offset * shadow_step * TEXTURE_PIXEL_SIZE;
	vec2 shadow_px = TEXTURE_PIXEL_SIZE * shadow_spread;
	float shadow_alpha = 0.0;
	float layer_alpha = 1.0;

	for (int i = 1; i <= 8; i++) {
		float layer = float(i);
		if (layer <= shadow_depth) {
			vec2 shadow_uv = UV - base_shadow_offset - depth_direction * layer;
			float shadow_sample = step(alpha_cutoff, texture(TEXTURE, clamp(shadow_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(shadow_uv);
			sample_uv = shadow_uv + vec2(shadow_px.x, 0.0);
			shadow_sample = max(shadow_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
			sample_uv = shadow_uv + vec2(-shadow_px.x, 0.0);
			shadow_sample = max(shadow_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
			sample_uv = shadow_uv + vec2(0.0, shadow_px.y);
			shadow_sample = max(shadow_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
			sample_uv = shadow_uv + vec2(0.0, -shadow_px.y);
			shadow_sample = max(shadow_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
			sample_uv = shadow_uv + vec2(shadow_px.x, shadow_px.y);
			shadow_sample = max(shadow_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
			sample_uv = shadow_uv + vec2(-shadow_px.x, shadow_px.y);
			shadow_sample = max(shadow_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
			sample_uv = shadow_uv + vec2(shadow_px.x, -shadow_px.y);
			shadow_sample = max(shadow_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
			sample_uv = shadow_uv + vec2(-shadow_px.x, -shadow_px.y);
			shadow_sample = max(shadow_sample, step(alpha_cutoff, texture(TEXTURE, clamp(sample_uv, vec2(0.0), vec2(1.0))).a) * uv_bounds(sample_uv));
			shadow_alpha = max(shadow_alpha, shadow_sample * layer_alpha);
			layer_alpha *= shadow_alpha_decay;
		}
	}

	vec3 fill = fill_color.rgb * fill_strength;
	fill += top_highlight.rgb * top_highlight.a * step(UV.y, highlight_cutoff);

	vec4 shadow = vec4(shadow_color.rgb, shadow_color.a * shadow_alpha);
	vec4 outline = vec4(outline_color.rgb, outline_color.a * outline_alpha);
	vec4 text = vec4(fill, fill_color.a * text_alpha);

	vec4 result = shadow;
	result.rgb = mix(result.rgb, outline.rgb, outline.a);
	result.a = max(result.a, outline.a);
	result.rgb = mix(result.rgb, text.rgb, text.a);
	result.a = max(result.a, text.a);

	COLOR = result;
}