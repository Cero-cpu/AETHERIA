shader_type canvas_item;

// ==============================================================================
// SHADER: Ataque Definitivo Dual — Vespera (Pixel Art Friendly)
// Sellos arcanos limpios en ambos brazos con anillos y cruz sutil.
// Versión simplificada sin onda de choque extra.
// ==============================================================================

uniform float progreso : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_nucleo : source_color = vec4(0.95, 0.85, 1.0, 1.0);
uniform vec4 color_primario : source_color = vec4(0.65, 0.15, 0.9, 1.0);
uniform vec4 color_secundario : source_color = vec4(0.35, 0.02, 0.75, 1.0);

mat2 rot2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

float dibuja_cruz_x(vec2 uv_local, float tamano) {
	vec2 p = abs(uv_local);
	float d = abs(p.x - p.y);
	float cruz = smoothstep(0.035 * tamano, 0.0, d) * step(max(p.x, p.y), tamano);
	return cruz;
}

vec4 dibuja_sello_arcano(vec2 uv, vec2 centro, float prog) {
	vec2 p = uv - centro;
	p.x *= 1.6;
	float dist = length(p);

	float radio_max = 0.38 * (0.2 + 0.8 * sqrt(prog));

	// Anillo principal
	float anillo = smoothstep(0.025, 0.0, abs(dist - radio_max));

	// Anillo interior
	float radio_in = radio_max * 0.65;
	float anillo_in = smoothstep(0.018, 0.0, abs(dist - radio_in)) * 0.7;

	// Cruz rotativa sutil
	vec2 p_rot = rot2d(prog * 1.57) * p;
	float cruz = dibuja_cruz_x(p_rot, radio_in * 0.85) * 0.8;

	float mascara = max(anillo, max(anillo_in, cruz));

	// Resplandor central contenido
	float resplandor = smoothstep(radio_in * 0.7, 0.0, dist) * 0.4;

	// Fade in/out limpio
	float alfa = (1.0 - smoothstep(0.75, 1.0, prog)) * smoothstep(0.0, 0.08, prog);
	float alfa_total = clamp((mascara + resplandor) * alfa, 0.0, 1.0);

	vec3 color_resp = mix(color_secundario.rgb, color_primario.rgb, mascara);
	color_resp = mix(color_resp, color_nucleo.rgb, resplandor + anillo * 0.4);

	return vec4(color_resp, alfa_total);
}

void fragment() {
	vec2 uv = UV;

	vec2 centro_izq = vec2(0.26, 0.5);
	vec2 centro_der = vec2(0.74, 0.5);

	vec4 sello_izq = dibuja_sello_arcano(uv, centro_izq, progreso);
	vec4 sello_der = dibuja_sello_arcano(uv, centro_der, progreso);

	vec3 col = max(sello_izq.rgb * sello_izq.a, sello_der.rgb * sello_der.a);
	float alpha = clamp(sello_izq.a + sello_der.a, 0.0, 1.0);

	COLOR = vec4(col, alpha);
}
