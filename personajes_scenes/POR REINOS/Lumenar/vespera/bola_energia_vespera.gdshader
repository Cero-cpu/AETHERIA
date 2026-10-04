shader_type canvas_item;

// ==============================================================
// SHADER: Bola de Fuego Mágico Morado - Vespera
// Efecto de energía arcana animada con núcleo luminoso,
// llamas retorcidas y chispas de plasma violeta.
// ==============================================================

uniform float velocidad : hint_range(0.1, 6.0) = 2.5;
uniform float intensidad : hint_range(0.1, 3.0) = 1.8;
uniform float radio_bola : hint_range(0.1, 1.0) = 0.62;
uniform vec4 color_nucleo : source_color = vec4(1.0, 0.92, 1.0, 1.0);
uniform vec4 color_medio : source_color = vec4(0.78, 0.08, 1.0, 1.0);
uniform vec4 color_llama : source_color = vec4(0.38, 0.0, 0.85, 1.0);
uniform vec4 color_borde : source_color = vec4(0.14, 0.0, 0.42, 1.0);

// ---- Funciones de Ruido ----

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

// Movimiento Browniano Fractal — genera el caos de las llamas
float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.55;
	float frec = 1.0;
	for (int i = 0; i < 6; i++) {
		v += amp * valor_ruido(p * frec);
		amp *= 0.48;
		frec *= 2.13;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0; // Centro en 0,0 — rango -1 a +1
	float t = TIME * velocidad;

	float dist = length(uv);

	// ---- Distorsión Turbulenta ----
	vec2 q;
	q.x = fbm(uv * 2.2 + vec2(t * 0.28, t * 0.45));
	q.y = fbm(uv * 2.2 + vec2(t * 0.51, -t * 0.31));
	vec2 uv_distorsionado = uv + 0.38 * q;
	float d = length(uv_distorsionado);

	// ---- Pulso de Energía ----
	float pulso = 0.96 + sin(t * 3.8) * 0.04 + sin(t * 7.1) * 0.015;

	// ---- Cuerpo Principal de Llama ----
	float llama = 1.0 - smoothstep(0.0, radio_bola * pulso, d);
	float turbulencia = fbm(uv * 3.5 + vec2(t * 0.35, t * 0.65));
	llama += turbulencia * 0.28 * (1.0 - dist);
	llama = clamp(llama, 0.0, 1.0);

	// ---- Resplandor Exterior ----
	float glow = exp(-dist * dist * 2.6) * 0.7;

	// ---- Núcleo Brillante ----
	float nucleo = exp(-dist * dist * 22.0) * pulso * 1.3;

	// ---- Espirales de Plasma ----
	float angulo = atan(uv.y, uv.x);
	float espiral_a = sin(angulo * 5.0 + t * 2.8 + dist * 8.0) * 0.5 + 0.5;
	float espiral_b = sin(angulo * 3.0 - t * 3.5 + dist * 5.0) * 0.5 + 0.5;
	float espiral = (espiral_a * 0.6 + espiral_b * 0.4) * exp(-dist * dist * 3.8) * turbulencia;

	// ---- Chispas en el Borde ----
	float ruido_borde = fbm(uv * 6.5 + vec2(-t * 0.55, t * 0.42));
	float borde_ext = smoothstep(0.52, 0.68, d - ruido_borde * 0.28);
	float borde_int = 1.0 - smoothstep(0.68, 0.92, d);
	float chispas = borde_ext * borde_int;

	// ---- Anillos de Energía ----
	float anillo = abs(sin(dist * 12.0 - t * 4.5)) * exp(-dist * dist * 4.0) * 0.3;

	// ---- Mezcla Final de Colores ----
	vec4 color_final = vec4(0.0);
	color_final = mix(color_final, color_borde, glow * 0.55);
	color_final = mix(color_final, color_llama, llama * 0.75);
	color_final = mix(color_final, color_llama + vec4(espiral * 0.4, 0.0, espiral * 0.3, 0.0), espiral * 0.9);
	color_final = mix(color_final, color_medio, llama * llama * 1.1);
	color_final = mix(color_final, color_nucleo, nucleo);

	// Chispas de plasma en violeta eléctrico
	color_final.rgb += vec3(0.55, 0.0, 1.0) * chispas * 0.9;

	// Anillos en el cuerpo
	color_final.rgb += vec3(0.65, 0.1, 1.0) * anillo;

	// ---- Alpha (Transparencia) ----
	float alpha = (glow * 0.9 + llama * 0.85 + espiral * 0.6 + chispas * 0.5 + anillo * 0.4) * intensidad;
	alpha = clamp(alpha, 0.0, 1.0);

	// Máscara circular suave para la bola
	float mascara = 1.0 - smoothstep(radio_bola * 0.85, radio_bola + 0.32, dist);
	alpha *= mascara;

	color_final.a = alpha;
	COLOR = color_final;
}
