shader_type canvas_item;

// Menggunakan tekstur noise lebih efisien daripada menghitung noise prosedural di dalam fragment shader.
uniform sampler2D noise_texture : repeat_enable, filter_linear_mipmap;

uniform vec4 lightning_color : source_color = vec4(0.5, 0.1, 1.0, 1.0); // Warna ungu
uniform float speed = 3.0;        // Kecepatan pergerakan petir
uniform float amplitude = 0.15;   // Seberapa lebar distorsi zig-zag
uniform float core_thickness = 0.002; // Ketebalan inti putih
uniform float glow_strength = 0.015;  // Intensitas pendaran

void fragment() {
    // 1. Pergerakan Waktu dan Pengambilan Sampel Noise
    // Kita menggeser koordinat Y seiring waktu untuk membuat efek animasi mengalir.
    vec2 noise_uv = vec2(UV.y, TIME * speed);
    float noise = texture(noise_texture, noise_uv).r;
    
    // 2. Distorsi UV
    // Normalisasi nilai noise dari [0, 1] menjadi [-0.5, 0.5] agar petir tetap berada di tengah.
    float offset = (noise - 0.5) * amplitude;
    
    // Menghitung jarak horizontal dari titik tengah (0.5) yang telah didistorsi.
    float dist = abs(UV.x - 0.5 - offset);
    
    // Cegah pembagian dengan nol yang dapat merusak shader (NaN).
    dist = max(dist, 0.0001);

    // 3. Perhitungan Intensitas Cahaya (Inverse Distance)
    // Daripada menggunakan linear interpolation (smoothstep), kita menggunakan invers jarak 
    // untuk mendapatkan falloff cahaya yang realistis seperti efek Bloom.
    float core_intensity = core_thickness / dist;
    float glow_intensity = glow_strength / dist;

    // 4. Komposisi Warna
    vec3 color = lightning_color.rgb * glow_intensity; // Pendaran luar
    color += vec3(core_intensity);                      // Inti putih
    
    // 5. Transparansi (Alpha)
    // Nilai alpha didapat dari kecerahan piksel. Semakin terang, semakin solid.
    float alpha = clamp(color.r + color.g + color.b, 0.0, 1.0);
    
    // Optimasi: Buang piksel yang hampir tidak terlihat untuk menghemat overdraw.
    if (alpha < 0.01) {
        discard;
    }

    COLOR = vec4(color, alpha);
}