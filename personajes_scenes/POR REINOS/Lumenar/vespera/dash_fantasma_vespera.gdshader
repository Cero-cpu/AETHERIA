shader_type canvas_item;
// Shader simple para las fantasmas/afterimages del dash de Vespera
// Versión limpia: silueta tintada suave sin exceso de brillo
uniform vec4 color_fantasma : source_color = vec4(0.5, 0.05, 0.85, 1.0);
uniform float alpha_base : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.05) {
		COLOR = vec4(0.0);
	} else {
		// Silueta tintada sutil — no tan brillante como para opacar al sprite real
		vec3 col = mix(tex.rgb * color_fantasma.rgb * 1.2, color_fantasma.rgb, 0.4);
		COLOR = vec4(col, tex.a * alpha_base);
	}
}
