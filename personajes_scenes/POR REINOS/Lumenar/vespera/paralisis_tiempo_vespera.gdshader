shader_type canvas_item;

// ==============================================================================
// SHADER: Parálisis Temporal (Chasquido de Tiempo) - Vespera
// Efecto de onda expansiva morada fluida estilo "piedra cayendo en el agua",
// con distorsión orgánica, micro-ripples, desaturación cromática y aura violeta.
// ==============================================================================

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Onda Expansiva Temporal
uniform float progreso : hint_range(0.0, 1.0) = 0.0;
uniform vec2 centro_pantalla = vec2(0.5, 0.5);
uniform float grosor_onda : hint_range(0.01, 0.3) = 0.09;
uniform float fuerza_distorsion : hint_range(0.0, 0.2) = 0.06;
uniform float frecuencia_deformacion : hint_range(1.0, 20.0) = 6.0;

// Estética Violeta / Morado Místico
uniform float desaturacion : hint_range(0.0, 1.0) = 0.85;
uniform vec4 color_congelado : source_color = vec4(0.48, 0.12, 0.88, 1.0); // Violeta místico profundo
uniform vec4 color_borde_onda : source_color = vec4(0.88, 0.35, 1.0, 1.0); // Morado neón brillante
uniform vec4 color_nucleo_onda : source_color = vec4(0.65, 0.15, 0.95, 1.0); // Magenta arcano
uniform float aberracion_fuerza : hint_range(0.0, 0.05) = 0.02;
uniform float brillo_relampago : hint_range(0.0, 3.0) = 0.0;

// Funciones de Ruido Fractal para Deformación Orgánica de Agua
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Vector desde el centro del chasquido
	vec2 dist_vec = uv - centro_pantalla;
	float dist_base = length(dist_vec);
	float angulo = atan(dist_vec.y, dist_vec.x);
	
	// Deformación orgánica estilo gota de agua en la superficie
	float ruido_angular = fbm(vec2(angulo * frecuencia_deformacion, progreso * 3.0));
	float deformacion_agua = (ruido_angular - 0.5) * 0.14 * smoothstep(0.0, 0.3, progreso);
	
	// Micro-ondulaciones secundarias (ripples de impacto)
	float micro_ondas = sin(dist_base * 45.0 - progreso * 18.0) * 0.015 * (1.0 - progreso);
	
	// Distancia deformada final
	float dist_deformada = dist_base + deformacion_agua + micro_ondas;
	
	// Radio dinámico de la onda
	float radio_maximo = 0.85;
	float radio_actual = progreso * radio_maximo;
	
	// Área envuelta por la burbuja de tiempo congelado deformada
	float dentro_burbuja = smoothstep(radio_actual + 0.03, radio_actual - 0.05, dist_deformada);
	
	// Cresta de la onda con grosor orgánico variable
	float dist_a_cresta = abs(dist_deformada - radio_actual);
	float factor_onda = smoothstep(grosor_onda * (0.8 + ruido_angular * 0.4), 0.0, dist_a_cresta);
	
	// Refracción y deformación acuosa de UVs
	vec2 direccion_normalizada = (dist_base > 0.0001) ? normalize(dist_vec) : vec2(0.0);
	float desfase_acuoso = sin(dist_deformada * 30.0 - progreso * 12.0);
	vec2 uv_distorsionada = uv + direccion_normalizada * factor_onda * fuerza_distorsion * desfase_acuoso;
	
	// Aberración Cromática (Separación RGB morado/violeta)
	float descalado_rgb = aberracion_fuerza * factor_onda;
	float r = texture(screen_texture, uv_distorsionada + vec2(descalado_rgb, 0.0)).r;
	float g = texture(screen_texture, uv_distorsionada).g;
	float b = texture(screen_texture, uv_distorsionada - vec2(descalado_rgb, 0.0)).b;
	vec3 color_pantalla = vec3(r, g, b);
	
	// Desaturación "Tiempo Congelado" dentro de la onda
	float luminancia = dot(color_pantalla, vec3(0.299, 0.587, 0.114));
	vec3 color_desaturado = vec3(luminancia);
	
	// Tinte morado místico profundo en la zona congelada
	vec3 color_temporal = mix(color_desaturado, color_desaturado * color_congelado.rgb * 2.2, 0.55);
	
	// Mezcla base de pantalla
	vec3 color_final = mix(color_pantalla, color_temporal, dentro_burbuja * desaturacion);
	
	// Resplandor de la onda morada fluida (borde brillante magenta/morado neón)
	vec3 color_anillo_morado = mix(color_borde_onda.rgb, color_nucleo_onda.rgb, ruido_angular);
	vec3 brillo_anillo = color_anillo_morado * (factor_onda * 3.2);
	color_final += brillo_anillo * smoothstep(0.0, 0.08, progreso) * (1.0 - smoothstep(0.85, 1.0, progreso));
	
	// Destello inicial violáceo del chasquido
	color_final += color_borde_onda.rgb * brillo_relampago * 0.8;
	
	COLOR = vec4(color_final, 1.0);
}
