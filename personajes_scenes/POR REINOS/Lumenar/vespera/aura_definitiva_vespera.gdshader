shader_type canvas_item;

// ==============================================================================
// SHADER: Aura de Definitiva — Vespera (Pixel Art Friendly)
// Versión limpia: contorno dilatado sutil, tinte violeta que preserva
// luminancia del sprite, y destellos moderados. Sin Voronoi, sin rayos,
// sin ondas de choque, sin aberración cromática.
// ==============================================================================

uniform float activo : hint_range(0.0, 1.0) = 1.0;
uniform float intensidad : hint_range(0.0, 3.0) = 1.8;
uniform float velocidad : hint_range(0.1, 5.0) = 2.5;
uniform float progreso_ult : hint_range(0.0, 1.0) = 0.0;

uniform float grosor_aura : hint_range(1.0, 5.0) = 3.0;
uniform float destellos_fuerza : hint_range(0.0, 2.0) = 1.2;

uniform vec4 color_nucleo : source_color = vec4(0.95, 0.85, 1.0, 1.0);
uniform vec4 color_intenso : source_color = vec4(0.65, 0.12, 0.9, 1.0);
uniform vec4 color_aura : source_color = vec4(0.4, 0.02, 0.8, 1.0);
uniform vec4 color_borde : source_color = vec4(0.15, 0.0, 0.35, 1.0);
uniform vec4 color_destello : source_color = vec4(0.9, 0.45, 0.95, 1.0);

// ---- Ruido simple ----
float hash21(vec2 p) {
	p = fract(p * vec2(127.34, 311.72));
	p += dot(p, p + 19.31);
	return fract(p.x * p.y);
}

float ruido_suave(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// FBM ligero — 3 octavas
float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	float frec = 1.0;
	for (int i = 0; i < 3; i++) {
		v += amp * ruido_suave(p * frec);
		amp *= 0.5;
		frec *= 2.0;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * velocidad;

	if (activo < 0.01) {
		COLOR = texture(TEXTURE, uv);
	} else {
		// ---- Muestra base del sprite ----
		vec4 color_sprite = texture(TEXTURE, uv);
		float tex_a = color_sprite.a;

		// ---- Borde de aura suave: muestreo radial simple ----
		vec2 ps = TEXTURE_PIXEL_SIZE;
		float aura_mask = 0.0;
		float muestras = 0.0;
		float radio_max = grosor_aura * (1.0 + progreso_ult * 0.2);

		// Muestreo en 8 direcciones cardinales y diagonales
		for (float r = 1.0; r <= 4.0; r += 1.0) {
			if (r > radio_max) break;
			float peso = 1.0 - r / (radio_max + 1.0);
			aura_mask += texture(TEXTURE, uv + vec2(r, 0.0) * ps).a * peso;
			aura_mask += texture(TEXTURE, uv - vec2(r, 0.0) * ps).a * peso;
			aura_mask += texture(TEXTURE, uv + vec2(0.0, r) * ps).a * peso;
			aura_mask += texture(TEXTURE, uv - vec2(0.0, r) * ps).a * peso;
			aura_mask += texture(TEXTURE, uv + vec2(r, r) * 0.707 * ps).a * peso * 0.7;
			aura_mask += texture(TEXTURE, uv - vec2(r, r) * 0.707 * ps).a * peso * 0.7;
			aura_mask += texture(TEXTURE, uv + vec2(r, -r) * 0.707 * ps).a * peso * 0.7;
			aura_mask += texture(TEXTURE, uv - vec2(r, -r) * 0.707 * ps).a * peso * 0.7;
			muestras += 6.8; // 4 * 1.0 + 4 * 0.7
		}
		aura_mask = clamp(aura_mask / max(muestras * 0.25, 1.0), 0.0, 1.0);
		float aura_exterior = aura_mask * (1.0 - tex_a);

		// ---- Ruido leve para variación orgánica del contorno ----
		float ruido = fbm(uv * 3.0 + vec2(0.0, -t * 0.5));
		float pulso = sin(t * 4.0) * 0.15 + 0.85;

		// ---- Colorear el contorno ----
		float intensidad_borde = (ruido * 0.5 + pulso * 0.5) * intensidad * activo;
		vec3 rgb_aura = mix(color_borde.rgb, color_aura.rgb, ruido * 0.6 + 0.4);
		rgb_aura = mix(rgb_aura, color_intenso.rgb, pulso * 0.35);

		// ---- Tinte interior preservando luminancia ----
		float luminancia = dot(color_sprite.rgb, vec3(0.299, 0.587, 0.114));
		float tinte_fuerza = (0.18 + ruido * 0.12 + progreso_ult * 0.15) * activo;
		vec3 sprite_tintado = mix(color_sprite.rgb, color_intenso.rgb * (luminancia * 1.1 + 0.2), tinte_fuerza * 0.4);
		// Zonas claras del sprite brillan ligeramente
		sprite_tintado = mix(sprite_tintado, color_nucleo.rgb, pow(luminancia, 2.5) * tinte_fuerza * 0.3);

		// ---- Destellos pequeños discretos ----
		vec2 uv_grid = floor(uv * 14.0);
		float ruido_destello = hash21(uv_grid + floor(t * 3.0));
		float destello_mascara = step(0.94, ruido_destello);
		vec2 uv_celda = fract(uv * 14.0) - vec2(0.5);
		float forma_chispa = exp(-dot(uv_celda, uv_celda) * 20.0);
		float destellos = destello_mascara * forma_chispa * (sin(t * 8.0 + ruido_destello * 6.0) * 0.5 + 0.5) * destellos_fuerza;
		destellos *= aura_mask * 0.6;

		// ---- Composición final ----
		vec4 resultado = vec4(0.0);
		resultado.rgb = mix(rgb_aura * (0.8 + intensidad_borde * 0.4), sprite_tintado, tex_a);

		float alpha_aura = aura_exterior * intensidad_borde * 0.6;
		resultado.a = clamp(tex_a + alpha_aura, 0.0, 1.0);

		// Destellos aditivos moderados
		resultado.rgb += color_destello.rgb * destellos * activo * 0.5;
		resultado.a = max(resultado.a, destellos * 0.3 * activo);

		COLOR = resultado;
	}
}
