shader_type canvas_item;

uniform vec4 lightning_color : source_color = vec4(0.2, 0.6, 1.0, 1.0);
uniform float core_size : hint_range(0.01, 0.1) = 0.03;
uniform float glow_intensity : hint_range(0.1, 5.0) = 2.0;
uniform float speed : hint_range(0.1, 20.0) = 15.0;
uniform float arc_thickness : hint_range(0.001, 0.05) = 0.005;

void fragment() {
    // Geser UV agar titik tengah berada di koordinat (0,0)
    vec2 uv = UV - 0.5;
    
    // Hitung jarak (radius) dan sudut (polar coordinate) dari pusat
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    
    vec3 final_color = vec3(0.0);
    
    // 1. Inti Energi (Core Glow) - Menggunakan inversi jarak
    // Semakin dekat ke 0, nilainya mendekati tak terhingga (terang)
    float core = core_size / (dist + 0.0001);
    final_color += core * vec3(1.0); 
    
    // 2. Horizontal Flare (Kilatan mendatar)
    // Distorsi sumbu Y untuk membuat pendaran melebar secara horizontal
    float flare = (core_size * 0.5) / (abs(uv.y) * 4.0 + dist * 2.0 + 0.0001);
    final_color += flare * lightning_color.rgb;
    
    // 3. Efek Cabang Petir (Procedural Arcs)
    float arcs = 0.0;
    
    // PERINGATAN: Looping dalam fragment shader berpotensi mahal.
    // Dibatasi maksimal 3 iterasi (3 cabang petir utama).
    for(int i = 1; i <= 3; i++) {
        float fi = float(i);
        float time_offset = TIME * speed * (0.8 + 0.2 * fi);
        
        // Rotasi dasar untuk setiap cabang
        float arc_angle = angle + time_offset * (mod(fi, 2.0) - 0.5);
        
        // Distorsi gelombang (Sin/Cos) untuk efek bergerigi (jagged)
        float wave = sin(dist * 20.0 * fi - time_offset) * 0.2 + 
                     cos(dist * 35.0 - time_offset * 1.2) * 0.1;
                     
        // Menghitung kedekatan piksel dengan garis cabang petir
        float line_dist = abs(fract(arc_angle / 3.1415 + wave) - 0.5);
        
        // Masking agar cabang memudar di tepi
        float mask = smoothstep(0.4, 0.0, dist);
        
        // Akumulasi intensitas
        arcs += (arc_thickness / (line_dist * dist + 0.0001)) * mask;
    }
    
    final_color += arcs * lightning_color.rgb * glow_intensity;
    
    // Batasi tepi agar tidak terpotong kasar (Vignette fade)
    float vignette = smoothstep(0.5, 0.1, dist);
    
    // Konversi intensitas warna menjadi Alpha untuk transparansi
    float alpha = clamp(length(final_color) * vignette, 0.0, 1.0);
    
    COLOR = vec4(final_color, alpha);
}