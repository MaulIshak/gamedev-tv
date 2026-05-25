shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 line_color : source_color = vec4(1.0, 0.9, 0.15, 1.0);
uniform float dash_count = 14.0;
uniform float dash_fill = 0.56;
uniform float core_thickness = 0.18;
uniform float glow_strength = 1.05;
uniform float gap_alpha = 0.18;

void fragment() {
    float dash_phase = fract(UV.x * dash_count);
    bool in_gap = dash_phase > dash_fill;

    float dist = abs(UV.y - 0.5);
    float core = 1.0 - smoothstep(core_thickness, 0.6, dist);
    float glow = 1.0 - smoothstep(0.9, 0.25, dist);

    vec3 color = line_color.rgb * (core + glow * glow_strength);
    float alpha = in_gap ? gap_alpha * line_color.a : line_color.a * max(core, 0.35);

    // boost final color for visibility and keep additive glow
    COLOR = vec4(color * 1.25, alpha);
}