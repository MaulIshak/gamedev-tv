shader_type canvas_item;
render_mode blend_mix;

group_uniforms Master;
uniform bool crt_enabled = true;
uniform float effect_mix : hint_range(0.0, 1.0) = 1.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 tint_color : source_color = vec4(0.96, 1.0, 0.98, 1.0);
uniform vec4 overlay_color : source_color = vec4(0.45, 0.95, 0.92, 0.08);

group_uniforms Geometry;
uniform float curvature : hint_range(0.0, 0.5) = 0.035;
uniform float zoom : hint_range(0.5, 1.5) = 1.0;
uniform float edge_fade : hint_range(0.0, 0.2) = 0.02;

group_uniforms ChromaticAberration;
uniform float rgb_split : hint_range(0.0, 0.03) = 0.0;
uniform vec2 rgb_direction = vec2(1.0, 0.0);
uniform float rgb_edge_boost : hint_range(0.0, 4.0) = 1.0;

group_uniforms Scanlines;
uniform float virtual_resolution_y : hint_range(64.0, 1080.0) = 270.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.28;
uniform float scanline_thickness : hint_range(0.05, 0.95) = 0.42;
uniform bool animate_scanlines = false;
uniform float scanline_speed : hint_range(-10.0, 10.0) = 0.0;

group_uniforms PhosphorMask;
uniform float virtual_resolution_x : hint_range(64.0, 1920.0) = 480.0;
uniform float mask_strength : hint_range(0.0, 1.0) = 0.11;
uniform float mask_scale : hint_range(1.0, 12.0) = 3.0;
uniform vec3 red_phosphor = vec3(1.0, 0.70, 0.70);
uniform vec3 green_phosphor = vec3(0.70, 1.0, 0.72);
uniform vec3 blue_phosphor = vec3(0.68, 0.76, 1.0);

group_uniforms Distortion;
uniform bool animate_jitter = false;
uniform float horizontal_jitter : hint_range(0.0, 0.03) = 0.0;
uniform float jitter_speed : hint_range(0.0, 60.0) = 18.0;
uniform bool animate_wobble = false;
uniform float vertical_wobble : hint_range(0.0, 0.03) = 0.0;
uniform float wobble_speed : hint_range(0.0, 20.0) = 2.5;
uniform float wobble_frequency : hint_range(0.0, 80.0) = 18.0;

group_uniforms NoiseFlicker;
uniform bool animate_grain = false;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.025;
uniform float grain_scale : hint_range(16.0, 512.0) = 180.0;
uniform float grain_speed : hint_range(0.0, 60.0) = 24.0;
uniform bool animate_flicker = false;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.0;
uniform float flicker_speed : hint_range(0.0, 60.0) = 12.0;

group_uniforms RollingBar;
uniform bool animate_rolling_bar = false;
uniform float rolling_bar_strength : hint_range(-1.0, 1.0) = 0.0;
uniform float rolling_bar_size : hint_range(0.01, 0.5) = 0.10;
uniform float rolling_bar_softness : hint_range(0.001, 0.5) = 0.12;
uniform float rolling_bar_speed : hint_range(-4.0, 4.0) = 0.12;

group_uniforms Vignette;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.16;
uniform float vignette_size : hint_range(0.0, 2.0) = 0.52;
uniform float vignette_softness : hint_range(0.1, 4.0) = 1.15;

group_uniforms EdgeGlow;
uniform float edge_glow_strength : hint_range(0.0, 2.0) = 0.06;
uniform float edge_glow_width : hint_range(0.0, 0.35) = 0.065;
uniform vec4 edge_glow_color : source_color = vec4(0.22, 0.95, 0.62, 1.0);

group_uniforms ColorGrade;
uniform float brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.0, 3.0) = 1.02;
uniform float saturation : hint_range(0.0, 3.0) = 1.02;
uniform float gamma : hint_range(0.2, 3.0) = 1.0;

group_uniforms Alpha;
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.001;

group_uniforms;

float hash12(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 curve_uv(vec2 uv) {
	vec2 centered = (uv - 0.5) / max(zoom, 0.0001);
	float radius = dot(centered, centered);
	centered *= 1.0 + radius * curvature;
	return centered + 0.5;
}

float bounds_mask(vec2 uv) {
	vec2 inside = smoothstep(vec2(0.0), vec2(edge_fade), uv) *
		(1.0 - smoothstep(vec2(1.0 - edge_fade), vec2(1.0), uv));
	return inside.x * inside.y;
}

vec3 apply_saturation(vec3 color, float amount) {
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(luminance), color, amount);
}

void fragment() {
	vec4 vertex_color = COLOR;
	vec3 base_color = texture(screen_texture, SCREEN_UV).rgb * tint_color.rgb * vertex_color.rgb;
	float base_alpha = vertex_color.a * opacity;

	if (!crt_enabled) {
		COLOR = vec4(base_color, base_alpha);
	} else {
		float jitter = 0.0;
		if (animate_jitter) {
			float jitter_line = floor(UV.y * virtual_resolution_y);
			float jitter_noise = hash12(vec2(jitter_line, floor(TIME * jitter_speed)));
			jitter = (jitter_noise - 0.5) * horizontal_jitter;
		}

		float wobble = 0.0;
		if (animate_wobble) {
			wobble = sin((UV.y * wobble_frequency) + (TIME * wobble_speed)) * vertical_wobble;
		}

		vec2 uv = curve_uv(UV + vec2(jitter + wobble, 0.0));
		float mask = bounds_mask(uv);

		float edge_distance = length((UV - 0.5) * 2.0);
		float edge_amount = clamp(edge_distance * rgb_edge_boost, 0.0, 1.0);
		vec2 split = normalize(rgb_direction + vec2(0.0001, 0.0)) * rgb_split * (0.35 + edge_amount);

		vec2 screen_offset = split;
		vec3 red_sample = texture(screen_texture, SCREEN_UV + screen_offset).rgb;
		vec3 green_sample = texture(screen_texture, SCREEN_UV).rgb;
		vec3 blue_sample = texture(screen_texture, SCREEN_UV - screen_offset).rgb;
		vec3 color = vec3(red_sample.r, green_sample.g, blue_sample.b) * tint_color.rgb * vertex_color.rgb;

		float scan_position = UV.y * virtual_resolution_y;
		if (animate_scanlines) {
			scan_position += TIME * scanline_speed;
		}
		float scan_wave = abs(fract(scan_position) - 0.5) * 2.0;
		float scanline = smoothstep(scanline_thickness, 1.0, scan_wave);
		color *= 1.0 - (scanline * scanline_strength);

		float phosphor_cell = mod(floor(UV.x * virtual_resolution_x / max(mask_scale, 0.0001)), 3.0);
		vec3 phosphor = red_phosphor;
		if (phosphor_cell >= 1.0 && phosphor_cell < 2.0) {
			phosphor = green_phosphor;
		} else if (phosphor_cell >= 2.0) {
			phosphor = blue_phosphor;
		}
		color = mix(color, color * phosphor, mask_strength);

		vec2 grain_time = vec2(0.0);
		if (animate_grain) {
			grain_time = vec2(floor(TIME * grain_speed));
		}
		float grain = hash12(floor(UV * grain_scale) + grain_time);
		color += (grain - 0.5) * grain_strength;

		float flicker = 0.5;
		if (animate_flicker) {
			flicker = sin(TIME * flicker_speed) * 0.5 + 0.5;
		}
		color *= 1.0 + ((flicker - 0.5) * flicker_strength);

		if (animate_rolling_bar) {
			float rolling_pos = fract(TIME * rolling_bar_speed);
			float rolling_dist = abs(UV.y - rolling_pos);
			rolling_dist = min(rolling_dist, 1.0 - rolling_dist);
			float rolling = 1.0 - smoothstep(rolling_bar_size, rolling_bar_size + rolling_bar_softness, rolling_dist);
			color *= 1.0 + rolling * rolling_bar_strength;
		}

		float vignette_distance = length((UV - 0.5) * vec2(1.15, 1.0));
		float vignette = smoothstep(vignette_size, vignette_size + vignette_softness, vignette_distance);
		color *= 1.0 - vignette * vignette_strength;

		float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
		float edge_glow = 1.0 - smoothstep(edge_glow_width, edge_glow_width * 2.0 + 0.0001, edge);
		color += edge_glow_color.rgb * edge_glow * edge_glow_strength;
		color = mix(color, overlay_color.rgb, overlay_color.a);

		color = (color - 0.5) * contrast + 0.5;
		color = apply_saturation(color, saturation);
		color += brightness;
		color = pow(max(color, vec3(0.0)), vec3(1.0 / max(gamma, 0.0001)));

		vec3 final_rgb = mix(base_color, color, effect_mix);
		float final_alpha = base_alpha * mask;

		if (final_alpha < alpha_threshold) {
			discard;
		}

		COLOR = vec4(final_rgb, final_alpha);
	}
}
