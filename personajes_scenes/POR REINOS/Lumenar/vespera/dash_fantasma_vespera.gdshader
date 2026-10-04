shader_type canvas_item;
// Shader simple para las fantasmas/afterimages del dash de Vespera
uniform vec4 color_fantasma : source_color = vec4(0.6, 0.0, 1.0, 1.0);
uniform float alpha_base : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Solo pinta donde hay píxeles del sprite
	if (tex.a < 0.05) {
		COLOR = vec4(0.0);
	} else {
		// Colorea la fantasma con el tono morado energético de Vespera
		vec3 col = mix(tex.rgb * color_fantasma.rgb * 1.8, color_fantasma.rgb, 0.55);
		COLOR = vec4(col, tex.a * alpha_base);
	}
}
