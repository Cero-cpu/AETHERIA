shader_type canvas_item;

// ==============================================================
// SHADER: Bola de Energía Arcana — Vespera (Pixel Art Friendly)
// Orbe compacto con núcleo luminoso, llama suave y glow contenido.
// Sin espirales, anillos ni chispas excesivas.
// ==============================================================

uniform float velocidad : hint_range(0.1, 4.0) = 2.0;
uniform float intensidad : hint_range(0.1, 2.0) = 1.2;
uniform float radio_bola : hint_range(0.1, 0.8) = 0.55;
uniform vec4 color_nucleo : source_color = vec4(0.95, 0.88, 1.0, 1.0);
uniform vec4 color_medio : source_color = vec4(0.65, 0.1, 0.9, 1.0);
uniform vec4 color_llama : source_color = vec4(0.35, 0.0, 0.75, 1.0);
uniform vec4 color_borde : source_color = vec4(0.12, 0.0, 0.35, 1.0);

// ---- Ruido simple ----
float hash21(vec2 p) {
	p = fract(p * vec2(127.34, 311.72));
	p += dot(p, p + 19.31);
	return fract(p.x * p.y);
}

float valor_ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// FBM ligero — solo 3 octavas
float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	float frec = 1.0;
	for (int i = 0; i < 3; i++) {
		v += amp * valor_ruido(p * frec);
		amp *= 0.5;
		frec *= 2.0;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float t = TIME * velocidad;
	float dist = length(uv);

	// ---- Distorsión sutil ----
	float turb = fbm(uv * 2.0 + vec2(t * 0.3, t * 0.4));
	vec2 uv_d = uv + 0.15 * (turb - 0.5);
	float d = length(uv_d);

	// ---- Pulso suave ----
	float pulso = 0.97 + sin(t * 3.0) * 0.03;

	// ---- Cuerpo de la llama ----
	float llama = 1.0 - smoothstep(0.0, radio_bola * pulso, d);
	llama += turb * 0.15 * (1.0 - dist);
	llama = clamp(llama, 0.0, 1.0);

	// ---- Glow exterior suave ----
	float glow = exp(-dist * dist * 3.5) * 0.45;

	// ---- Núcleo brillante ----
	float nucleo = exp(-dist * dist * 18.0) * pulso;

	// ---- Mezcla de colores ----
	vec4 color_final = vec4(0.0);
	color_final = mix(color_final, color_borde, glow * 0.4);
	color_final = mix(color_final, color_llama, llama * 0.7);
	color_final = mix(color_final, color_medio, llama * llama);
	color_final = mix(color_final, color_nucleo, nucleo);

	// ---- Alpha ----
	float alpha = (glow * 0.7 + llama * 0.8) * intensidad;
	alpha = clamp(alpha, 0.0, 1.0);

	// Máscara circular
	float mascara = 1.0 - smoothstep(radio_bola * 0.9, radio_bola + 0.2, dist);
	alpha *= mascara;

	color_final.a = alpha;
	COLOR = color_final;
}
