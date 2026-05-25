shader_type canvas_item;
render_mode blend_mix;

group_uniforms Motion;
uniform float float_speed : hint_range(0.05, 4.0) = 0.55;
uniform float float_amplitude : hint_range(0.0, 16.0) = 2.5;
uniform float segment_width : hint_range(8.0, 400.0) = 58.0;
uniform float segment_phase_step : hint_range(0.0, 6.28318) = 0.9;
uniform float base_phase : hint_range(0.0, 6.28318) = 0.0;

uniform bool enable_horizontal_sway = false;
uniform float sway_amplitude : hint_range(0.0, 8.0) = 0.6;
uniform float sway_frequency : hint_range(0.1, 4.0) = 0.7;

uniform bool separate_per_line = true;
uniform float line_height : hint_range(8.0, 256.0) = 40.0;
uniform float line_phase_step : hint_range(0.0, 6.28318) = 0.45;

void vertex() {
	float safe_segment_width = max(segment_width, 1.0);
	float safe_line_height = max(line_height, 1.0);

	float segment_index = floor(max(VERTEX.x, 0.0) / safe_segment_width);
	float line_index = floor(max(VERTEX.y, 0.0) / safe_line_height);

	float t = TIME * float_speed + base_phase + segment_index * segment_phase_step;
	if (separate_per_line) {
		t += line_index * line_phase_step;
	}

	VERTEX.y += sin(t) * float_amplitude;

	if (enable_horizontal_sway) {
		VERTEX.x += cos(t * sway_frequency) * sway_amplitude;
	}
}

void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
}
