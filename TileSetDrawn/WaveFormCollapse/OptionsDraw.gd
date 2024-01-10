extends Node2D

@onready var vector_sprite_mapping: Dictionary = {
	Vector2i(0,0): $"0/0_0",
	Vector2i(1,0): $"0/1_0",
	Vector2i(2,0): $"0/2_0",
	Vector2i(3,0): $"0/3_0",
	Vector2i(4,0): $"0/4_0",
	Vector2i(5,0): $"0/5_0",
	Vector2i(6,0): $"0/6_0",
	Vector2i(7,0): $"0/7_0",
	
	Vector2i(0,1): $"1/0_1",
	Vector2i(1,1): $"1/1_1",
	Vector2i(2,1): $"1/2_1",
	Vector2i(3,1): $"1/3_1",
	Vector2i(4,1): $"1/4_1",
	Vector2i(5,1): $"1/5_1",
	Vector2i(6,1): $"1/6_1",
	Vector2i(7,1): $"1/7_1",
	
	Vector2i(0,2): $"2/0_2",
	Vector2i(1,2): $"2/1_2",
	Vector2i(2,2): $"2/2_2",
	Vector2i(3,2): $"2/3_2",
	Vector2i(4,2): $"2/4_2",
	Vector2i(5,2): $"2/5_2",
	Vector2i(6,2): $"2/6_2",
	Vector2i(7,2): $"2/7_2",
	
	Vector2i(0,3): $"3/0_3",
	Vector2i(1,3): $"3/1_3",
	Vector2i(2,3): $"3/2_3",
	Vector2i(3,3): $"3/3_3",
	Vector2i(4,3): $"3/4_3",
	Vector2i(5,3): $"3/5_3",
	Vector2i(6,3): $"3/6_3",
	Vector2i(7,3): $"3/7_3",
	
	Vector2i(0,4): $"4/0_4",
	Vector2i(1,4): $"4/1_4",
	Vector2i(2,4): $"4/2_4",
	Vector2i(3,4): $"4/3_4",
	Vector2i(4,4): $"4/4_4",
	Vector2i(5,4): $"4/5_4",
	Vector2i(6,4): $"4/6_4",
	Vector2i(7,4): $"4/7_4",
	
	Vector2i(0,5): $"5/0_5",
	Vector2i(1,5): $"5/1_5",
	Vector2i(2,5): $"5/2_5",
	Vector2i(3,5): $"5/3_5",
	Vector2i(4,5): $"5/4_5",
	Vector2i(5,5): $"5/5_5",
	Vector2i(6,5): $"5/6_5",
	Vector2i(7,5): $"5/7_5",
	
	Vector2i(0,6): $"6/0_6",
	Vector2i(1,6): $"6/1_6",
	Vector2i(2,6): $"6/2_6",
	Vector2i(3,6): $"6/3_6",
	Vector2i(4,6): $"6/4_6",
	Vector2i(5,6): $"6/5_6",
	Vector2i(6,6): $"6/6_6",
	Vector2i(7,6): $"6/7_6",
	
	Vector2i(0,7): $"7/0_7",
	Vector2i(1,7): $"7/1_7",
	Vector2i(2,7): $"7/2_7",
	Vector2i(3,7): $"7/3_7",
	Vector2i(4,7): $"7/4_7",
	Vector2i(5,7): $"7/5_7",
	Vector2i(6,7): $"7/6_7",
	Vector2i(7,7): $"7/7_7",
}

@export var settings: Array[Vector2i] = [] : set = _set_settings

func _set_settings(value: Array[Vector2i]) -> void:
	settings = value
	for key in vector_sprite_mapping.keys():
		var sprite : Sprite2D = vector_sprite_mapping.get(key)
		sprite.material.set_shader_parameter("on", key in settings)

