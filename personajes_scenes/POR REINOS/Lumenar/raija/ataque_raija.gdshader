shader_type canvas_item;

// ==============================================================
// SHADER: Ataque Melee Frenético Radiante Magenta/Violeta - Raija
// Adaptado a la paleta exacta de Raija (#ed12fc, #9f39ae, #470877, #ffffff):
// • Resplandor ultrabrillante (Rim Plasma Glow) en Neón Magenta y Violeta
// • Arcos de energía y rayos frenéticos recorriendo la silueta
// • Flash de impacto instantáneo (Hit Flash 100%) en CADA golpe
// • Aberración cromática violenta en la dirección del movimiento
// • Chispas de alta frecuencia y distorsión de velocidad
// ==============================================================

uniform float activo : hint_range(0.0, 1.0) = 0.0;
uniform float progreso : hint_range(0.0, 1.0) = 0.0; // 0.0 inicio del tajo, 1.0 final
uniform float direccion : hint_range(-1.0, 1.0) = 1.0;
uniform float flash_hit : hint_range(0.0, 1.0) = 0.0;

uniform float rim_grosor : hint_range(1.0, 6.0) = 3.5;
uniform float brillo_rim : hint_range(0.0, 8.0) = 5.8;
uniform float aberracion_fuerza : hint_range(0.0, 0.08) = 0.038;

// Paleta tomada directamente de la animación idle y ataques de Raija
uniform vec4 color_magenta_neon : source_color = vec4(0.97, 0.07, 0.98, 1.0);  // #f813fb Neón Magenta de Raija
uniform vec4 color_violeta_arcano : source_color = vec4(0.62, 0.22, 0.68, 1.0); // #9f39ae Violeta Intenso
uniform vec4 color_nucleo_blanco : source_color = vec4(1.0, 0.94, 1.0, 1.0);   // Núcleo Blanco Radiante

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

	if (activo < 0.01 && flash_hit < 0.01) {
		COLOR = texture(TEXTURE, uv);
	} else {
		// ---- 1. Aberración Cromática Frenética en Neón Magenta ----
		float aber = (aberracion_fuerza + flash_hit * 0.02) * activo * (1.0 - progreso * 0.4);
		float r = texture(TEXTURE, uv + vec2(-aber * 2.5 * direccion, aber * 0.2)).r;
		float g = texture(TEXTURE, uv + vec2(-aber * 1.0 * direccion, 0.0)).g;
		float b = texture(TEXTURE, uv + vec2(aber * 1.2 * direccion, -aber * 0.2)).b;
		float a = texture(TEXTURE, uv).a;

		vec4 color_sprite = vec4(r, g, b, a);

		// ---- 2. Detección de Borde (Rim de Plasma Magenta) ----
		vec2 ps = TEXTURE_PIXEL_SIZE;
		float borde_alpha = 0.0;
		float muestras = 0.0;
		for (float dx = -rim_grosor; dx <= rim_grosor; dx += 1.5) {
			for (float dy = -rim_grosor; dy <= rim_grosor; dy += 1.5) {
				float d = sqrt(dx * dx + dy * dy);
				if (d <= rim_grosor && d >= 0.5) {
					borde_alpha += texture(TEXTURE, uv + vec2(dx, dy) * ps).a;
					muestras += 1.0;
				}
			}
		}
		borde_alpha = clamp(borde_alpha / max(muestras, 1.0), 0.0, 1.0);
		float rim = borde_alpha * (1.0 - a);

		// ---- 3. Arcos Eléctricos y Ruido Frenético Magenta/Violeta ----
		float ruido_electrico = ruido(uv * 18.0 + vec2(t * 42.0 * direccion, t * 28.0));
		float chispa_frenetica = step(0.58, ruido_electrico);
		float pulso_rapido = sin(t * 38.0) * 0.35 + 0.65;
		rim *= (ruido_electrico * 0.8 + chispa_frenetica * 0.6) * pulso_rapido;

		// Mezcla de color entre Magenta Neón y Violeta Arcano
		vec3 color_energia = mix(color_violeta_arcano.rgb, color_magenta_neon.rgb, ruido_electrico);

		// Tinte sobre la silueta del sprite durante el tajo
		float tinte_cuerpo = activo * (0.55 + chispa_frenetica * 0.3) * a;
		color_sprite.rgb = mix(color_sprite.rgb, color_energia, tinte_cuerpo * 0.65);
		color_sprite.rgb = mix(color_sprite.rgb, color_nucleo_blanco.rgb, tinte_cuerpo * 0.35);

		// Añadir Contorno Resplandeciente (Rim Glow Magenta)
		color_sprite.rgb += color_energia * rim * brillo_rim * activo;

		// ---- 4. Chispas y Rayos Neón de Alta Frecuencia ----
		float band_spark = sin((uv.y * 32.0 + uv.x * 22.0) + t * 55.0);
		band_spark = smoothstep(0.75, 1.0, band_spark);
		float chispas = band_spark * rim * 3.2 * activo;
		color_sprite.rgb += color_nucleo_blanco.rgb * chispas * brillo_rim;

		// ---- 5. Flash Radiante Instantáneo en CADA Golpe (Hit Flash 100%) ----
		if (flash_hit > 0.01) {
			vec3 col_flash_intenso = mix(color_magenta_neon.rgb, color_nucleo_blanco.rgb, 0.80);
			color_sprite.rgb = mix(color_sprite.rgb, col_flash_intenso, flash_hit * 0.95);
		}

		color_sprite.a = max(a, rim * activo * 0.95);
		COLOR = color_sprite;
	}
}
