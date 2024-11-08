extends BaseDispatcher

const BIT_32_IN_BYTES: int = 4

@export var input_int_array: PackedInt32Array = [1, 2, 3, 4]
@export var input_int_array_binding: int = 0
@export var input_float_array: PackedFloat32Array = [1.001, 2.002, 3.003, 4.004]
@export var input_float_array_binding: int = 1
@export var output_int_array_size: int = 4 * BIT_32_IN_BYTES
@export var output_int_array_binding: int = 4
@export var output_float_array_size: int = 4 * BIT_32_IN_BYTES
@export var output_float_array_binding: int = 5

@export var render_target: TextureRect

func translate_buffer_inputs() -> void:
	"""Translate local exports to the base buffer byte arrays before dispatch"""
	self.glsl_buffer_inputs.append(
		GLSLBufferInput.new(
			input_int_array.to_byte_array(), input_int_array_binding
		)
	)
	self.glsl_buffer_inputs.append(
		GLSLBufferInput.new(
			input_float_array.to_byte_array(), input_float_array_binding
		)
	)
	self.glsl_buffer_outputs.append(
		GLSLBufferOutput.new(output_int_array_size, output_int_array_binding)
	)
	self.glsl_buffer_outputs.append(
		GLSLBufferOutput.new(output_float_array_size, output_float_array_binding)
	)

func translate_buffer_outputs() -> void:
	print(self.glsl_buffer_outputs[0].bytes.to_int32_array())
	print(self.glsl_buffer_outputs[1].bytes.to_float32_array())
	render_target.texture = glsl_texture_outputs[0].output_texture

func dispatch() -> void:
	
	translate_buffer_inputs()
	
	await base_dispatch()
	
	translate_buffer_outputs()
