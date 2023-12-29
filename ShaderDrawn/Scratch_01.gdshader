shader_type canvas_item;


void fragment() {
	vec2 st = FRAGCOORD.xy;
	int x = int(st.x);
	int y = int(st.y);
	
	float grey = 0.0;
	
	if (x % 2 == y % 2) {
		grey = 1.0;
	}
	
	vec3 color = vec3(grey);
	
	COLOR = vec4(color, 1.0);
}
