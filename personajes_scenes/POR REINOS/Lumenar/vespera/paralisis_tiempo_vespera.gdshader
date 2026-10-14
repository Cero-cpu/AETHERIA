shader_type canvas_item;

// ==============================================================================
// SHADER: Parálisis Temporal (Chasquido) — Vespera (Pixel Art Friendly)
// Onda expansiva limpia con desaturación, tinte violeta sutil y distorsión
// mínima. Sin micro-ripples ni aberración cromática excesiva.
// ==============================================================================

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float progreso : hint_range(0.0, 1.0) = 0.0;
uniform vec2 centro_pantalla = vec2(0.5, 0.5);
uniform float grosor_onda : hint_range(0.01, 0.2) = 0.06;
uniform float fuerza_distorsion : hint_range(0.0, 0.1) = 0.03;

uniform float desaturacion : hint_range(0.0, 1.0) = 0.75;
uniform vec4 color_congelado : source_color = vec4(0.4, 0.12, 0.8, 1.0);
uniform vec4 color_borde_onda : source_color = vec4(0.75, 0.3, 0.95, 1.0);
uniform float brillo_relampago : hint_range(0.0, 2.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;

	vec2 dist_vec = uv - centro_pantalla;
	float dist = length(dist_vec);

	// Radio dinámico de la onda
	float radio_actual = progreso * 0.8;

	// Zona congelada: dentro de la burbuja
	float dentro_burbuja = smoothstep(radio_actual + 0.02, radio_actual - 0.04, dist);

	// Cresta de la onda — borde limpio
	float dist_a_cresta = abs(dist - radio_actual);
	float factor_onda = smoothstep(grosor_onda, 0.0, dist_a_cresta);

	// Distorsión leve en la cresta de la onda
	vec2 dir_norm = (dist > 0.001) ? normalize(dist_vec) : vec2(0.0);
	float desfase = sin(dist * 20.0 - progreso * 8.0);
	vec2 uv_dist = uv + dir_norm * factor_onda * fuerza_distorsion * desfase;

	// Muestreo de pantalla (sin aberración cromática)
	vec3 color_pantalla = texture(screen_texture, uv_dist).rgb;

	// Desaturación dentro de la burbuja temporal
	float luminancia = dot(color_pantalla, vec3(0.299, 0.587, 0.114));
	vec3 color_desaturado = vec3(luminancia);

	// Tinte violeta sutil
	vec3 color_temporal = mix(color_desaturado, color_desaturado * color_congelado.rgb * 1.8, 0.4);

	// Mezcla
	vec3 color_final = mix(color_pantalla, color_temporal, dentro_burbuja * desaturacion);

	// Borde de la onda — resplandor limpio
	float fade_onda = smoothstep(0.0, 0.06, progreso) * (1.0 - smoothstep(0.85, 1.0, progreso));
	color_final += color_borde_onda.rgb * factor_onda * 1.8 * fade_onda;

	// Flash inicial del chasquido
	color_final += color_borde_onda.rgb * brillo_relampago * 0.5;

	COLOR = vec4(color_final, 1.0);
}
