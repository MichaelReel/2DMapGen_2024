shader_type canvas_item;

uniform bool on;

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = on ? vec4(1.0) : vec4(vec3(0.0), 1.0);
}

