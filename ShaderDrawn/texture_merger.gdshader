shader_type canvas_item;

uniform sampler2D noise: source_color;
uniform sampler2D base_mass: source_color;
uniform float mix_value = 500;

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = mix(texture(noise, UV.xy), texture(base_mass, UV.xy), mix_value);
}
