shader_type canvas_item;
render_mode blend_add;  // Modo aditivo = colores que BRILLAN sobre todo

// ==============================================================
// SHADER: Onda de Corte Demoníaca - Raija
// Múltiples capas de energía violeta/magenta HDR
// Modo blend_add para efecto de emisión/brillo real
// ==============================================================

uniform vec4 color_magenta : source_color = vec4(1.0, 0.04, 1.0, 1.0);    // Magenta puro intenso
uniform vec4 color_violeta : source_color = vec4(0.55, 0.0, 1.0, 1.0);    // Violeta eléctrico
uniform vec4 color_rosa    : source_color = vec4(1.0, 0.2, 0.8, 1.0);     // Rosa neón
uniform vec4 color_nucleo  : source_color = vec4(1.0, 1.0, 1.0, 1.0);     // Blanco puro

uniform float desvanecimiento : hint_range(0.0, 1.0) = 0.0;
uniform float curvatura : hint_range(0.5, 3.0) = 1.6;
uniform float intensidad : hint_range(0.5, 4.0) = 2.2;   // Multiplicador HDR

// ── Ruido ────────────────────────────────────────────────────
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
		mix(hash2(i),              hash2(i + vec2(1.0, 0.0)), f.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

// Ruido fractal multicapa (fbm) para más detalle
float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * ruido(p);
		p  = p * 2.1 + vec2(0.3, 1.7);
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	vec2 p = uv - vec2(0.5, 0.5);

	// ── Forma de la onda (arco curvo orientado >>>>) ──────────
	float dist_x = p.x + (p.y * p.y * curvatura - 0.2);

	// Ruido frenético multicapa para deformar el filo
	float plasma     = fbm(uv * 10.0 + vec2(-t * 30.0, t * 12.0));
	float plasma_lento = fbm(uv * 5.0  + vec2(-t * 12.0, -t * 6.0));

	// Distorsionar ligeramente el filo con el plasma
	float dist_xd = dist_x + (plasma - 0.5) * 0.06;

	// ── CAPAS DE INTENSIDAD ───────────────────────────────────

	// 1. Núcleo ultra delgado y brillante (filo de la espada)
	float g_nucleo = 0.012;
	float nucleo = smoothstep(g_nucleo, 0.0, abs(dist_xd));
	nucleo = pow(nucleo, 0.6);  // Más denso en el centro

	// 2. Capa media: el cuerpo del corte
	float g_cuerpo = 0.06;
	float cuerpo = smoothstep(g_cuerpo, 0.0, abs(dist_xd));

	// 3. Aura interna brillante
	float g_aura1 = 0.15;
	float aura1 = smoothstep(g_aura1, 0.0, abs(dist_x)) * (0.5 + 0.5 * plasma_lento);

	// 4. Aura externa nebulosa y demoníaca
	float g_aura2 = 0.32;
	float aura2 = smoothstep(g_aura2, 0.0, abs(dist_x)) * (0.3 + 0.7 * plasma_lento);
	aura2 *= (0.4 + 0.6 * ruido(uv * 4.0 + vec2(-t * 8.0, t * 3.0)));

	// 5. Estela energética que disminuye hacia atrás (izquierda)
	float estela = smoothstep(-0.55, 0.45, p.x);
	float corte_vert = smoothstep(0.5, 0.38, abs(p.y));  // Limitar arriba/abajo

	// Aplica estela a todas las capas
	nucleo  *= estela * corte_vert;
	cuerpo  *= estela * corte_vert;
	aura1   *= estela * corte_vert;
	aura2   *= estela * corte_vert * smoothstep(-0.7, 0.1, p.x); // Aura aún más larga

	// Fluctuación frenética del plasma sobre el cuerpo
	cuerpo  *= (0.5 + 0.5 * plasma);
	aura1   *= (0.6 + 0.4 * plasma_lento);

	// ── COMPOSICIÓN DE COLORES (HDR aditivo) ─────────────────

	// Aura externa: violeta profundo + poca intensidad
	vec3 col = color_violeta.rgb * aura2 * 0.8;

	// Aura interna: mezcla violeta-magenta
	col += mix(color_violeta.rgb, color_magenta.rgb, plasma_lento) * aura1 * 1.2;

	// Cuerpo: magenta/rosa brillante
	col += mix(color_magenta.rgb, color_rosa.rgb, plasma) * cuerpo * 2.0;

	// Núcleo: blanco puro sobreexpuesto
	col += color_nucleo.rgb * nucleo * 3.5;

	// ── Multiplicar por intensidad HDR ────────────────────────
	col *= intensidad;

	// Alpha: combina todas las capas (blend_add, el alpha controla aportación)
	float alpha = clamp(aura2 * 0.4 + aura1 * 0.6 + cuerpo + nucleo, 0.0, 1.0);
	alpha *= (1.0 - desvanecimiento);

	COLOR = vec4(col, alpha);
}
