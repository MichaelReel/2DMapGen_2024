extends Node2D

@onready var vector_sprite_mapping: Dictionary = {
	Vector2i(0,0): $"0/0_0",
	Vector2i(1,0): $"0/1_0",
	Vector2i(2,0): $"0/2_0",
	Vector2i(3,0): $"0/3_0",
	Vector2i(4,0): $"0/4_0",
	Vector2i(5,0): $"0/5_0",
	Vector2i(0,1): $"1/0_1",
	Vector2i(1,1): $"1/1_1",
	Vector2i(2,1): $"1/2_1",
	Vector2i(3,1): $"1/3_1",
	Vector2i(4,1): $"1/4_1",
	Vector2i(5,1): $"1/5_1",
	Vector2i(0,2): $"2/0_2",
	Vector2i(1,2): $"2/1_2",
	Vector2i(2,2): $"2/2_2",
	Vector2i(3,2): $"2/3_2",
	Vector2i(4,2): $"2/4_2",
	Vector2i(5,2): $"2/5_2",
}

@export var settings: Array[Vector2i] = [] : set = _set_settings

func _set_settings(value: Array[Vector2i]) -> void:
	settings = value
	for key in vector_sprite_mapping.keys():
		var sprite : Sprite2D = vector_sprite_mapping.get(key)
		sprite.material.set_shader_parameter("on", key in settings)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
