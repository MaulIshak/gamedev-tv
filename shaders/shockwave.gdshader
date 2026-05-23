shader_type canvas_item;

// Menggunakan source_color agar mendukung HDR jika WorldEnvironment Glow diaktifkan
uniform vec4 glow_color : source_color = vec4(0.2, 0.6, 2.0, 1.0); 

// Kontrol utama untuk animasi dari kecil ke besar (0.0 ke 1.0)
uniform float progress : hint_range(0.0, 1.0) = 0.5;

// Ketebalan dasar dari petir
uniform float ring_thickness : hint_range(0.001, 0.1) = 0.015;

// Tekstur noise (Gunakan FastNoiseLite di inspector, pastikan Seamless diaktifkan)
uniform sampler2D noise_texture : repeat_enable;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.15;
uniform float time_scale = 3.0;

void fragment() {
    // Geser titik tengah UV ke (0, 0)
    vec2 centered_uv = UV - 0.5;
    
    // Hitung jarak dari pusat
    float dist = length(centered_uv);
    
    // Kalkulasi koordinat polar (sudut) untuk memetakan noise melingkar
    // atan() mengembalikan nilai dari -PI hingga PI
    float angle = atan(centered_uv.y, centered_uv.x);
    
    // Mapping UV untuk noise: X berdasarkan sudut, Y bergerak seiring waktu
    // Dibagi 6.28318 (2 * PI) untuk menormalkan dari -1.0 hingga 1.0
    vec2 noise_uv = vec2(angle / 6.28318 + 0.5, dist - TIME * time_scale);
    
    // Ambil nilai noise (0.0 ke 1.0) dan ubah ke rentang (-1.0 ke 1.0)
    float noise_val = texture(noise_texture, noise_uv).r * 2.0 - 1.0;
    
    // Ekspansi radius berdasarkan progress
    // Dikalikan 0.5 karena rentang maksimum UV dari tengah ke ujung adalah 0.5
    float current_radius = progress * 0.5;
    
    // Distorsi jarak matematis. Distorsi juga mengecil jika radius kecil.
    float distorted_dist = dist + (noise_val * distortion_strength * progress);
    
    // Teknik Inverse Distance untuk efek neon/glow alami
    // Menambahkan +0.001 untuk mencegah error pembagian dengan nol (division by zero)
    float glow = ring_thickness / abs(distorted_dist - current_radius + 0.001);
    
    // Masking: hilangkan di bagian tengah, pudarkan saat progress mencapai 1.0
    float alpha_mask = smoothstep(0.0, 0.1, progress) * smoothstep(1.0, 0.8, progress);
    
    // Masking tepi: pastikan efek tidak terpotong kasar di ujung quad/sprite
    float edge_mask = smoothstep(0.5, 0.45, dist);
    
    glow *= alpha_mask * edge_mask;
    
    // Output akhir. Warna RGB bisa menembus >1.0 untuk efek bloom/Glow
    vec3 final_color = glow_color.rgb * glow;
    
    // Alpha di-clamp di 1.0 agar blending transparansi tetap logis
    COLOR = vec4(final_color, min(glow, 1.0) * glow_color.a);
}