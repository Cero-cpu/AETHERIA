shader_type canvas_item;

// ==============================================================================
// SHADER: Dominio de la Noche (Efecto Oscurecimiento de Entorno) - Vespera
// Oscurece la pantalla envolviendo el entorno en un crepúsculo de noche profunda
// suave y limpio, y resalta a Vespera en un haz de luz arcana e iluminada.
// ==============================================================================

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float intensidad_noche : hint_range(0.0, 1.0) = 0.0;
uniform vec2 centro_pantalla = vec2(0.5, 0.5);
uniform float radio_luz_vespera : hint_range(0.1, 1.0) = 0.38;
uniform float suavidad_borde : hint_range(0.05, 0.6) = 0.28;
uniform vec4 color_noche : source_color = vec4(0.06, 0.04, 0.18, 1.0); // Azul medianoche místico
uniform vec4 color_resplandor_aura : source_color = vec4(0.7, 0.2, 1.0, 1.0); // Violeta místico

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Vector y distancia radial desde Vespera
	vec2 dist_vec = uv - centro_pantalla;
	float dist = length(dist_vec);
	
	// Máscara de luz alrededor de Vespera (Foco/Spotlight arcano)
	float halo_luz = 1.0 - smoothstep(radio_luz_vespera - suavidad_borde, radio_luz_vespera + suavidad_borde, dist);
	
	// Textura real de la pantalla
	vec4 color_pantalla = texture(screen_texture, uv);
	
	// Oscurecer ambiente exterior estilo noche profunda limpio y fluido
	vec3 ambiente_noche = color_pantalla.rgb * color_noche.rgb * 1.6;
	
	// Tinte violeta suave en el borde del halo de Vespera
	float borde_halo = smoothstep(radio_luz_vespera - suavidad_borde, radio_luz_vespera, dist) * (1.0 - smoothstep(radio_luz_vespera, radio_luz_vespera + suavidad_borde, dist));
	ambiente_noche += color_resplandor_aura.rgb * borde_halo * 0.45;
	
	// Mezclar zona iluminada (Vespera) con el entorno oscurecido según intensidad_noche
	vec3 color_escena = mix(color_pantalla.rgb, ambiente_noche, (1.0 - halo_luz));
	vec3 color_final = mix(color_pantalla.rgb, color_escena, intensidad_noche);
	
	COLOR = vec4(color_final, 1.0);
}
