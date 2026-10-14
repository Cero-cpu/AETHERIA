shader_type canvas_item;

// ==============================================================
// SHADER: Orbe de Energía Mágica - Proyectil Imp Mágico (Lumenar)
// Esfera de energía arcana luminosa con núcleo brillante y aura pulsante
// ==============================================================

uniform float velocidad : hint_range(0.5, 8.0) = 4.0;
uniform float radio : hint_range(0.1, 0.9) = 0.45;
uniform vec4 color_nucleo : source_color = vec4(1.0, 1.0, 0.9, 1.0);
uniform vec4 color_aura : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform vec4 color_borde : source_color = vec4(0.1, 0.3, 0.9, 0.0);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);

	// Distorsión y oscilación
	float angle = atan(uv.y, uv.x);
	float osc = sin(angle * 4.0 + TIME * velocidad) * 0.06;
	float dist = d + osc;

	if (dist > radio + 0.35) {
		COLOR = vec4(0.0);
	} else {
		// Gradiente desde el centro
		float factor_nucleo = clamp(1.0 - (dist / radio), 0.0, 1.0);
		float factor_aura = clamp(1.0 - ((dist - radio * 0.3) / (radio * 0.8)), 0.0, 1.0);

		vec4 col = mix(color_borde, color_aura, factor_aura);
		col = mix(col, color_nucleo, pow(factor_nucleo, 2.0));
		col.a = clamp(col.a * (1.0 - smoothstep(radio, radio + 0.3, dist)), 0.0, 1.0);

		COLOR = col;
	}
}
