shader_type canvas_item;

// ==============================================================================
// SHADER: Aura Épica de Definitiva (Nivel AAA / Profesional) - Vespera
//
// MEJORAS GRÁFICAS Y ESTÉTICAS PROFESIONALES:
// 1. Mantenimiento de Luminancia: Preserva sombras, líneas y detalles del sprite.
// 2. Transición Suave de Bordes (Anti-Clipping): Elimina bordes rectangulares duros.
// 3. Fuego Arcano Voronoi/FBM: Flujo orgánico de plasma violeta sin efecto de "ruido de TV".
// 4. Contorno Especular Fresnel: Iluminación de borde reactiva a la silueta.
// 5. Destellos Cósmicos con Gradiente Radialmente Suave (Efecto Polvo de Estrellas).
// ==============================================================================

uniform float activo : hint_range(0.0, 1.0) = 1.0;
uniform float intensidad : hint_range(0.0, 5.0) = 2.8;
uniform float velocidad : hint_range(0.1, 8.0) = 3.5;
uniform float progreso_ult : hint_range(0.0, 1.0) = 0.0;

uniform float grosor_aura : hint_range(1.0, 8.0) = 4.5;
uniform float aberracion_fuerza : hint_range(0.0, 0.08) = 0.03;
uniform float turbulencia : hint_range(0.0, 3.0) = 1.4;
uniform float destellos_fuerza : hint_range(0.0, 5.0) = 2.8;
uniform float frecuencia_pulso : hint_range(1.0, 20.0) = 8.0;

// Paleta de Colores Armónica Mística de Vespera (HDR Tailored)
uniform vec4 color_nucleo : source_color = vec4(0.98, 0.88, 1.0, 1.0);     // Núcleo blanco-rosa radiante
uniform vec4 color_intenso : source_color = vec4(0.78, 0.12, 1.0, 1.0);    // Violeta eléctrico fulgurante
uniform vec4 color_aura : source_color = vec4(0.48, 0.02, 0.92, 1.0);       // Morado regio profundo
uniform vec4 color_borde : source_color = vec4(0.16, 0.0, 0.42, 1.0);      // Sombra arcana púrpura
uniform vec4 color_destello : source_color = vec4(1.0, 0.5, 0.98, 1.0);     // Destello magenta cósmico

// ---- Funciones de Ruido C-2 Continuo & FBM ====

float hash21(vec2 p) {
	p = fract(p * vec2(127.34, 311.72));
	p += dot(p, p + 19.31);
	return fract(p.x * p.y);
}

float ruido_suave(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Suavizado Quintic (Hermite C2) para evitar aristas duras
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Voronoi orgánico para los filamentos de plasma mágico
float voronoi_plasma(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float dist_min = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash21(n + g), hash21(n + g + 55.4));
			o = 0.5 + 0.5 * sin(TIME * 2.5 + 6.2831 * o);
			vec2 r = g + o - f;
			float d = dot(r, r);
			dist_min = min(dist_min, d);
		}
	}
	return sqrt(dist_min);
}

// FBM Fractal con suavizado de 5 capas
float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	float frec = 1.0;
	for (int i = 0; i < 5; i++) {
		v += amp * ruido_suave(p * frec);
		amp *= 0.48;
		frec *= 2.15;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * velocidad;

	// Si el shader no está activo, muestra la textura base intacta
	if (activo < 0.01) {
		COLOR = texture(TEXTURE, uv);
	} else {
		// ---- 0. Atenuación Suave de Bordes (Previene recortes en caja rectangulares) ----
		float mascara_caja = smoothstep(0.0, 0.08, uv.x) * smoothstep(1.0, 0.92, uv.x) *
		                     smoothstep(0.0, 0.08, uv.y) * smoothstep(1.0, 0.92, uv.y);

		// ---- 1. Aberración Cromática Direccional Espectral ----
		float aber = aberracion_fuerza * activo * (1.0 + sin(t * 3.0) * 0.25 + progreso_ult * 0.4);
		vec2 offset_r = vec2(-aber * 1.4, aber * 0.4);
		vec2 offset_g = vec2(0.0, -aber * 0.7);
		vec2 offset_b = vec2(aber * 1.4, aber * 0.3);

		float tex_r = texture(TEXTURE, uv + offset_r).r;
		float tex_g = texture(TEXTURE, uv + offset_g).g;
		float tex_b = texture(TEXTURE, uv + offset_b).b;
		float tex_a = texture(TEXTURE, uv).a;

		vec4 color_sprite = vec4(tex_r, tex_g, tex_b, tex_a);

		// ---- 2. Rim / Silhouette Dilated Aura (Exploración Radial Suave) ----
		vec2 ps = TEXTURE_PIXEL_SIZE;
		float aura_mask = 0.0;
		float muestras = 0.0;
		
		float radio_max = grosor_aura * (1.0 + progreso_ult * 0.35);
		for (float r = 1.0; r <= 8.0; r += 1.5) {
			if (r > radio_max) break;
			float paso_ang = 6.28318 / (r * 4.0);
			for (float a = 0.0; a < 6.28318; a += paso_ang) {
				vec2 offset = vec2(cos(a), sin(a)) * r * ps;
				float sample_a = texture(TEXTURE, uv + offset).a;
				aura_mask += sample_a * (1.0 - r / (radio_max + 1.0));
				muestras += 1.0;
			}
		}
		aura_mask = clamp(aura_mask / max(muestras * 0.2, 1.0), 0.0, 1.0);
		float aura_exterior = aura_mask * (1.0 - tex_a);

		// ---- 3. Distorsión Mística Orgánica (Domain Warping + Voronoi) ----
		vec2 q;
		q.x = fbm(uv * 2.8 + vec2(t * 0.35, t * 0.6));
		q.y = fbm(uv * 2.8 + vec2(-t * 0.5, t * 0.45));
		
		vec2 uv_warped = uv + q * 0.16 * turbulencia;
		float fuego_ruido = fbm(uv_warped * 4.5 + vec2(0.0, -t * 1.2));
		float voronoi_ondas = 1.0 - voronoi_plasma(uv * 4.0 + vec2(0.0, -t * 0.8));

		// ---- 4. Pulso Radial & Beams Arcanos ----
		vec2 uv_centrada = uv - vec2(0.5, 0.5);
		float dist_centro = length(uv_centrada);
		float angulo = atan(uv_centrada.y, uv_centrada.x);

		float pulso = sin(t * frecuencia_pulso - dist_centro * 10.0) * 0.5 + 0.5;
		float onda_choque = exp(-pow(dist_centro * 3.8 - fract(t * 0.75) * 2.8, 2.0)) * (1.0 - dist_centro);

		float rayos = sin(angulo * 7.0 + t * 3.5 + fuego_ruido * 3.5) * 0.5 + 0.5;
		rayos = pow(rayos, 3.5) * exp(-dist_centro * 2.2);

		// ---- 5. Polvo de Estrellas / Destellos Esféricos ----
		vec2 uv_grid = floor(uv * 22.0);
		float ruido_destello = hash21(uv_grid + floor(t * 5.0));
		float destello_mascara = step(0.91 - progreso_ult * 0.06, ruido_destello);
		
		// Coordenadas locales dentro de la celda de la chispa para forma circular suave
		vec2 uv_celda = fract(uv * 22.0) - vec2(0.5);
		float forma_chispa = exp(-dot(uv_celda, uv_celda) * 16.0);
		
		float destellos = destello_mascara * forma_chispa * (sin(t * 12.0 + ruido_destello * 8.0) * 0.5 + 0.5) * destellos_fuerza;
		destellos *= (aura_mask + 0.25);

		// ---- 6. Preservación de Luminancia y Mapeo HDR de Colores ----
		// Extraer luminancia del sprite de Vespera para no aplanar el arte en píxeles
		float luminancia = dot(color_sprite.rgb, vec3(0.299, 0.587, 0.114));

		// Gradiente de aura exterior
		vec4 color_aura_final = mix(color_borde, color_aura, fuego_ruido * 0.8 + voronoi_ondas * 0.2);
		color_aura_final = mix(color_aura_final, color_intenso, pulso * 0.65 + onda_choque * 0.45);
		color_aura_final = mix(color_aura_final, color_nucleo, rayos * 0.55 + fuego_ruido * 0.35);

		float intensidad_borde = (fuego_ruido * 0.55 + pulso * 0.35 + rayos * 0.45 + voronoi_ondas * 0.35) * intensidad * activo;
		vec3 rgb_aura = color_aura_final.rgb * (1.15 + intensidad_borde);

		// Tinte interior preservando luces y sombras del arte original
		float tinte_fuerza = (0.28 + fuego_ruido * 0.25 + pulso * 0.18 + progreso_ult * 0.25) * activo;
		vec3 sprite_tintado = mix(color_sprite.rgb, color_intenso.rgb * (luminancia * 1.2 + 0.2), tinte_fuerza * 0.5);
		sprite_tintado = mix(sprite_tintado, color_nucleo.rgb, pow(luminancia, 2.0) * tinte_fuerza * 0.4);

		// ---- 7. Composición Final Anti-Clipping ----
		vec4 resultado = vec4(0.0);

		// Mezclar sprite con aura exterior
		resultado.rgb = mix(rgb_aura, sprite_tintado, tex_a);
		
		// Opacidad con máscara de borde para evitar cortes en caja
		float alpha_aura = aura_exterior * intensidad_borde * 0.92;
		resultado.a = clamp(tex_a + alpha_aura, 0.0, 1.0) * mascara_caja;

		// Añadir destellos additivos
		resultado.rgb += color_destello.rgb * destellos * activo * mascara_caja;
		resultado.a = max(resultado.a, destellos * 0.65 * activo * mascara_caja);

		COLOR = resultado;
	}
}
