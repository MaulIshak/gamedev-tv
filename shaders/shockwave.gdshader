shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.2, 0.6, 2.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float ring_thickness : hint_range(0.001, 0.1) = 0.015;
uniform sampler2D noise_texture : repeat_enable;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.15;
uniform float time_scale = 3.0;
uniform float cycle_duration = 1.6;
uniform float grow_duration = 0.45;
uniform float hold_duration = 0.65;
uniform float shrink_duration = 0.35;
uniform float min_progress : hint_range(0.01, 0.5) = 0.06;

float get_anim_progress() {
    float total_duration = max(grow_duration + hold_duration + shrink_duration, 0.001);
    float cycle = max(cycle_duration, total_duration);
    float t = mod(TIME + progress * cycle, cycle);

    if (t < grow_duration) {
        return mix(min_progress, 1.0, t / max(grow_duration, 0.001));
    }

    t -= grow_duration;
    if (t < hold_duration) {
        return 1.0;
    }

    t -= hold_duration;
    if (t < shrink_duration) {
        return mix(1.0, min_progress, t / max(shrink_duration, 0.001));
    }

    return min_progress;
}

void fragment() {
    vec2 centered_uv = UV - 0.5;
    float dist = length(centered_uv);
    float angle = atan(centered_uv.y, centered_uv.x);
    vec2 noise_uv = vec2(angle / 6.28318 + 0.5, dist - TIME * time_scale);
    float noise_val = texture(noise_texture, noise_uv).r * 2.0 - 1.0;
    float anim_progress = get_anim_progress();
    float current_radius = anim_progress * 0.5;
    float distorted_dist = dist + (noise_val * distortion_strength * anim_progress);
    float glow = ring_thickness / abs(distorted_dist - current_radius + 0.001);

    float alpha_mask = smoothstep(0.0, 0.08, anim_progress);
    if (anim_progress >= 1.0) {
        alpha_mask = 1.0;
    } else {
        float shrink_fade = clamp((anim_progress - min_progress) / max(1.0 - min_progress, 0.001), 0.0, 1.0);
        alpha_mask *= shrink_fade;
    }

    float edge_mask = smoothstep(0.5, 0.45, dist);
    glow *= alpha_mask * edge_mask;

    vec3 final_color = glow_color.rgb * glow;
    COLOR = vec4(final_color, min(glow, 1.0) * glow_color.a);
}