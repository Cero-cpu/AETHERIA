shader_type canvas_item;

// ==============================================================================
// SHADER: Hit Flash / Impacto Blanqueado - Imp Mágico (Lumenar)
// Destello blanco radiante con silueta exterior resaltada para Game Feel
// ==============================================================================

uniform float flash_fuerza : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_flash : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float grosor_borde : hint_range(1.0, 6.0) = 3.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	if (flash_fuerza < 0.001) {
		COLOR = tex;
	} else {
		vec2 ps = TEXTURE_PIXEL_SIZE;
		float alpha_borde = 0.0;
		float muestras = 0.0;

		// Detección de silueta exterior
		for (float x = -grosor_borde; x <= grosor_borde; x += 1.0) {
			for (float y = -grosor_borde; y <= grosor_borde; y += 1.0) {
				float dist = sqrt(x * x + y * y);
				if (dist <= grosor_borde && dist >= 0.5) {
					alpha_borde += texture(TEXTURE, UV + vec2(x, y) * ps).a;
					muestras += 1.0;
				}
			}
		}
		alpha_borde = clamp(alpha_borde / max(muestras * 0.25, 1.0), 0.0, 1.0);
		float rim_exterior = alpha_borde * (1.0 - tex.a);

		// Blanqueado puro e intenso
		vec3 blanco_puro = vec3(2.5, 2.5, 2.5) * color_flash.rgb;
		vec3 body_color = mix(tex.rgb, blanco_puro, flash_fuerza);
		vec3 outline_color = vec3(2.5, 2.5, 2.5) * color_flash.rgb;

		vec3 col_final = mix(outline_color, body_color, tex.a);
		float alpha_final = clamp(tex.a + rim_exterior * flash_fuerza * 0.9, 0.0, 1.0);

		COLOR = vec4(col_final, alpha_final);
	}
}
