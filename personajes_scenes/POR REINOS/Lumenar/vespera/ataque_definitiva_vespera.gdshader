shader_type canvas_item;

// ==============================================================================
// SHADER PROCEDURAL: Ataque Definitivo Dual - Vespera
// Genera dos sellos arcanos místico-violetas con runas en 'X' y ondas de choque
// expansivas que emergen de los brazos izquierdo y derecho sin usar sprites.
// ==============================================================================

uniform float progreso : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_nucleo : source_color = vec4(0.98, 0.85, 1.0, 1.0);
uniform vec4 color_primario : source_color = vec4(0.75, 0.15, 1.0, 1.0);
uniform vec4 color_secundario : source_color = vec4(0.40, 0.02, 0.85, 1.0);

// Función auxiliar de rotación 2D
mat2 rot2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

// Dibujo de runa en forma de X / Cruz Arcana
float dibuja_cruz_x(vec2 uv_local, float tamano) {
	vec2 p = abs(uv_local);
	// Distancia a las diagonales en X
	float d = abs(p.x - p.y);
	float cruz = smoothstep(0.04 * tamano, 0.0, d) * step(max(p.x, p.y), tamano);
	return cruz;
}

// Dibujo de un Sello Arcano completo en una posición UV dada
vec4 dibuja_sello_arcano(vec2 uv, vec2 centro, float prog) {
	vec2 p = uv - centro;
	// Ajuste de aspecto para que el círculo se mantenga simétrico
	p.x *= 1.6;
	
	float dist = length(p);
	
	// Radio de expansión de la onda
	float radio_max = 0.44 * (0.2 + 0.8 * sqrt(prog));
	
	// 1. Anillo Principal Exterior
	float ancho_anillo = 0.03;
	float anillo = smoothstep(ancho_anillo, 0.0, abs(dist - radio_max));
	
	// 2. Anillo Secundario Interior
	float radio_in = radio_max * 0.68;
	float anillo_in = smoothstep(0.02, 0.0, abs(dist - radio_in));
	
	// 3. Runa en 'X' central rotatoria
	vec2 p_rot = rot2d(prog * 3.14159 * 0.5) * p;
	float cruz = dibuja_cruz_x(p_rot, radio_in * 0.9);
	
	// 4. Onda de choque expansiva de resplandor
	float onda_ext = smoothstep(radio_max, radio_max + 0.10, dist) * (1.0 - smoothstep(radio_max + 0.10, radio_max + 0.22, dist));
	
	// Combinar elementos visuales
	float mascara_total = max(anillo, max(anillo_in * 0.85, cruz * 0.95)) + onda_ext * 0.45;
	
	// Resplandor central místico
	float resplandor_centro = smoothstep(radio_in * 0.8, 0.0, dist) * 0.65;
	
	// Desvanecimiento suave según el progreso del ataque
	float alfa_desvanecimiento = (1.0 - smoothstep(0.70, 1.0, prog)) * smoothstep(0.0, 0.10, prog);
	float alfa_total = clamp((mascara_total + resplandor_centro) * alfa_desvanecimiento, 0.0, 1.0);
	
	// Composición de color violeta arcano brillante
	vec3 color_resplandor = mix(color_secundario.rgb, color_primario.rgb, mascara_total);
	color_resplandor = mix(color_resplandor, color_nucleo.rgb, resplandor_centro + anillo * 0.6);
	
	return vec4(color_resplandor, alfa_total);
}

void fragment() {
	vec2 uv = UV;
	
	// Posición de los sellos arcanos en los dos brazos (Izquierdo: 0.26, Derecho: 0.74)
	vec2 centro_izq = vec2(0.26, 0.5);
	vec2 centro_der = vec2(0.74, 0.5);
	
	vec4 sello_izq = dibuja_sello_arcano(uv, centro_izq, progreso);
	vec4 sello_der = dibuja_sello_arcano(uv, centro_der, progreso);
	
	// Combinación de la energía de ambos brazos
	vec3 col_combinado = max(sello_izq.rgb * sello_izq.a, sello_der.rgb * sello_der.a);
	float alpha_combinado = clamp(sello_izq.a + sello_der.a, 0.0, 1.0);
	
	COLOR = vec4(col_combinado, alpha_combinado);
}
