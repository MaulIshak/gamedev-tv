shader_type canvas_item;
render_mode unshaded, blend_mix;

group_uniforms Box;
uniform vec4 fill_color : source_color = vec4(0.78, 0.84, 0.66, 0.95);
uniform vec4 outline_color : source_color = vec4(0.02, 0.07, 0.09, 1.0);
uniform float outline_size : hint_range(0.0, 8.0) = 2.0;
uniform vec2 rect_size = vec2(120.0, 32.0);

group_uniforms Shadow;
uniform vec4 shadow_color : source_color = vec4(0.0, 0.035, 0.04, 0.75);
uniform vec2 shadow_offset = vec2(3.0, 4.0);
uniform float shadow_depth : hint_range(0.0, 12.0) = 3.0;
uniform vec2 shadow_depth_offset = vec2(1.0, 1.0);
uniform float shadow_alpha_decay : hint_range(0.1, 1.0) = 0.78;

group_uniforms Highlight;
uniform vec4 top_highlight : source_color = vec4(1.0, 1.0, 1.0, 0.12);
uniform float highlight_height : hint_range(0.0, 1.0) = 0.28;

bool in_box(vec2 point, vec2 minimum, vec2 maximum) {
	return point.x >= minimum.x && point.y >= minimum.y && point.x <= maximum.x && point.y <= maximum.y;
}

void fragment() {
	vec2 pixel = UV * rect_size;
	vec2 depth_offset = shadow_offset + shadow_depth_offset * shadow_depth;
	vec2 content_min = vec2(outline_size);
	vec2 content_max = rect_size - max(depth_offset, vec2(0.0)) - vec2(outline_size);
	vec4 result = vec4(0.0);

	// Static layered shadow drawing (loop-free and pow-free!)
	if (shadow_depth >= 3.0) {
		vec2 offset = shadow_offset + shadow_depth_offset * 2.0;
		float alpha = shadow_color.a * shadow_alpha_decay * shadow_alpha_decay;
		if (in_box(pixel - offset, content_min, content_max)) {
			result = vec4(shadow_color.rgb, alpha);
		}
	}
	if (shadow_depth >= 2.0) {
		vec2 offset = shadow_offset + shadow_depth_offset;
		float alpha = shadow_color.a * shadow_alpha_decay;
		if (in_box(pixel - offset, content_min, content_max)) {
			result = mix(result, vec4(shadow_color.rgb, alpha), alpha);
		}
	}
	if (shadow_depth >= 1.0) {
		vec2 offset = shadow_offset;
		float alpha = shadow_color.a;
		if (in_box(pixel - offset, content_min, content_max)) {
			result = mix(result, vec4(shadow_color.rgb, alpha), alpha);
		}
	}

	if (in_box(pixel, content_min, content_max)) {
		float edge_distance = min(
			min(pixel.x - content_min.x, content_max.x - pixel.x),
			min(pixel.y - content_min.y, content_max.y - pixel.y)
		);

		if (edge_distance <= outline_size) {
			result = outline_color;
		} else {
			float highlight = smoothstep(highlight_height, 0.0, UV.y);
			vec4 body = fill_color;
			body.rgb = mix(body.rgb, top_highlight.rgb, top_highlight.a * highlight);
			result = body;
		}
	}

	COLOR = result;
}
