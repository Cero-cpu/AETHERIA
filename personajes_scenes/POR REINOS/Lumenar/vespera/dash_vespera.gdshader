shader_type canvas_item;

// ==============================================================
// SHADER: Efecto de Dash — Vespera (Pixel Art Friendly)
// Versión limpia y sutil:
// • Aberración cromática suave en dirección del dash
// • Tinte violeta leve que preserva el sprite
// • Contorno sutil de 1px energético
// • Alpha ligeramente fantasmal
// ==============================================================

uniform float activo : hint_range(0.0, 1.0) = 0.0;
uniform float direccion : hint_range(-1.0, 1.0) = 1.0;
uniform float progreso : hint_range(0.0, 1.0) = 0.0;

uniform float aberracion_fuerza : hint_range(0.0, 0.03) = 0.008;
uniform vec4 color_energia : source_color = vec4(0.6, 0.1, 0.9, 1.0);
uniform vec4 color_nucleo : source_color = vec4(0.9, 0.75, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;

	if (activo < 0.01) {
		COLOR = texture(TEXTURE, uv);
	} else {
		// ---- Aberración Cromática sutil ----
		float aber = aberracion_fuerza * activo * (1.0 - progreso * 0.5);
		float r = texture(TEXTURE, uv + vec2(-aber * direccion, 0.0)).r;
		float g = texture(TEXTURE, uv).g;
		float b = texture(TEXTURE, uv + vec2(aber * 0.5 * direccion, 0.0)).b;
		float a = texture(TEXTURE, uv).a;

		vec4 color_sprite = vec4(r, g, b, a);

		// ---- Contorno sutil de 1px ----
		vec2 ps = TEXTURE_PIXEL_SIZE;
		float borde = 0.0;
		borde += texture(TEXTURE, uv + vec2(ps.x, 0.0)).a;
		borde += texture(TEXTURE, uv - vec2(ps.x, 0.0)).a;
		borde += texture(TEXTURE, uv + vec2(0.0, ps.y)).a;
		borde += texture(TEXTURE, uv - vec2(0.0, ps.y)).a;
		borde = clamp(borde, 0.0, 1.0);
		float rim = borde * (1.0 - a);

		// ---- Tinte violeta leve sobre el sprite ----
		float tinte = activo * 0.2 * a;
		color_sprite.rgb = mix(color_sprite.rgb, color_energia.rgb, tinte);
		// Realzar ligeramente las zonas claras
		float luma = dot(color_sprite.rgb, vec3(0.299, 0.587, 0.114));
		color_sprite.rgb = mix(color_sprite.rgb, color_nucleo.rgb, tinte * luma * 0.3);

		// ---- Contorno energético sutil ----
		color_sprite.rgb += color_energia.rgb * rim * 1.2 * activo;
		color_sprite.a = max(a, rim * activo * 0.5);

		// ---- Alpha fantasmal ----
		color_sprite.a *= mix(1.0, 0.85, activo);

		COLOR = color_sprite;
	}
}
