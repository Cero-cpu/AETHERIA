shader_type canvas_item;

// ==============================================================
// SHADER: Efecto de Dash Mágico - Vespera
// Aplicado al AnimatedSprite2D durante el dash:
// • Aberración cromática en dirección del dash
// • Contorno/rim morado energético
// • Tinte violeta con pulso de energía
// • Distorsión de velocidad en el borde
// ==============================================================

uniform float activo : hint_range(0.0, 1.0) = 0.0;
uniform float direccion : hint_range(-1.0, 1.0) = 1.0;
uniform float progreso : hint_range(0.0, 1.0) = 0.0; // 0 = inicio dash, 1 = final

uniform float aberracion_fuerza : hint_range(0.0, 0.06) = 0.022;
uniform float rim_grosor : hint_range(1.0, 4.0) = 2.5;
uniform float brillo_rim : hint_range(0.0, 4.0) = 2.8;

uniform vec4 color_rim : source_color = vec4(0.72, 0.0, 1.0, 1.0);
uniform vec4 color_energia : source_color = vec4(0.55, 0.0, 0.95, 1.0);
uniform vec4 color_nucleo : source_color = vec4(1.0, 0.85, 1.0, 1.0);

float hash2(vec2 p) {
	p = fract(p * vec2(127.34, 311.72));
	p += dot(p, p + 19.31);
	return fract(p.x * p.y);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// ---- Muestra normal si dash no está activo ----
	if (activo < 0.01) {
		COLOR = texture(TEXTURE, uv);
	} else {
		// ---- Aberración Cromática en Dirección del Dash ----
		float aber = aberracion_fuerza * activo * (1.0 - progreso * 0.4);
		float r = texture(TEXTURE, uv + vec2(-aber * 2.2 * direccion, 0.0)).r;
		float g = texture(TEXTURE, uv + vec2(-aber * 1.1 * direccion, aber * 0.1)).g;
		float b = texture(TEXTURE, uv + vec2(aber * 0.4 * direccion, 0.0)).b;
		float a = texture(TEXTURE, uv).a;

		vec4 color_sprite = vec4(r, g, b, a);

		// ---- Detección de Borde (Rim) ----
		vec2 ps = TEXTURE_PIXEL_SIZE;
		float borde_alpha = 0.0;
		float muestras = 0.0;
		for (float dx = -rim_grosor; dx <= rim_grosor; dx += 1.0) {
			for (float dy = -rim_grosor; dy <= rim_grosor; dy += 1.0) {
				float d = sqrt(dx * dx + dy * dy);
				if (d <= rim_grosor && d >= 0.5) {
					borde_alpha += texture(TEXTURE, uv + vec2(dx, dy) * ps).a;
					muestras += 1.0;
				}
			}
		}
		borde_alpha = clamp(borde_alpha / max(muestras, 1.0), 0.0, 1.0);
		float rim = borde_alpha * (1.0 - a); // Solo donde no hay sprite

		// ---- Ruido Energético para el Rim ----
		float ruido_rim = ruido(uv * 8.0 + vec2(t * 5.0 * direccion, t * 2.5)) * 0.6 + 0.4;
		float pulso_rim = sin(t * 9.0) * 0.25 + 0.75;
		rim *= ruido_rim * pulso_rim;

		// ---- Tinte de Energía Sobre el Sprite ----
		float ruido_sprite = ruido(uv * 5.0 + vec2(t * 3.0 * -direccion, t * 1.5)) * 0.5 + 0.5;
		float pulso_energia = sin(t * 11.0) * 0.2 + 0.8;
		float tinte_fuerza = activo * 0.38 * ruido_sprite * pulso_energia * a;

		// Mezcla hacia morado/blanco violeta en el núcleo
		vec3 color_base = color_sprite.rgb;
		vec3 tinte_final = mix(color_base, color_energia.rgb * pulso_energia, tinte_fuerza * 0.6);
		tinte_final = mix(tinte_final, color_nucleo.rgb, tinte_fuerza * 0.25);
		color_sprite.rgb = tinte_final;

		// ---- Chispas de Velocidad en el Rim ----
		float chispa_y = fract(uv.y * 18.0 + t * 8.0);
		float chispa_band = 1.0 - abs(chispa_y - 0.5) * 4.0;
		chispa_band = max(chispa_band, 0.0);
		float chispa_ruido = ruido(vec2(uv.y * 12.0, t * 4.0));
		float chispas = chispa_band * chispa_ruido * rim * 1.5;

		// ---- Componer el Color Final ----
		// Rim base morado
		color_sprite.rgb += color_rim.rgb * rim * brillo_rim * activo;
		color_sprite.a = max(a, rim * activo * 0.85);

		// Chispas de plasma en el contorno
		color_sprite.rgb += vec3(0.8, 0.2, 1.0) * chispas * brillo_rim * activo;

		// Alpha del personaje levemente fantasmal durante el dash
		color_sprite.a *= mix(1.0, 0.82, activo * (1.0 - progreso * 0.3));

		COLOR = color_sprite;
	}
}
