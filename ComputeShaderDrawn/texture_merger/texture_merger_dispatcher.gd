extends Node

@export_category("Input Textures")
@export var noise_texture: NoiseTexture2D
@export var base_texture: GradientTexture2D
@export var mix_value: float = 5000.0

@export_group("Requirements")
@export_file("*.glsl") var _compute_shader: String
@export var _renderer: TextureRect

var _rd: RenderingDevice
var _glsl_local_size: Vector3i 
var _shader: RID
var _buffer: RID
var _noise_texure: RID
var _base_texure: RID
var _output_texure: RID
var _uniform_set : RID

var _image_size: Vector2i

var _bindings: Array[RDUniform] = []


#region DISPATCH STEPS

func _create_local_rendering_device() -> void:
	_rd = RenderingServer.create_local_rendering_device()
	if not _rd:
		set_process(false)
		printerr("Compute shaders are not available")

func _load_glsl_shader() -> void:
	_glsl_local_size = _get_layout_from_glsl(_compute_shader)
	
	var shader_file: RDShaderFile = load(_compute_shader) as RDShaderFile
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	_shader = _rd.shader_create_from_spirv(shader_spirv)


func _prepare_float_array_input_data() -> void:
	# Only need to include the mix_value in the input for now
	var input_buffer: Array[float] = [mix_value]
	
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	var input := PackedFloat32Array(input_buffer)
	print("Input: ", input)
	var input_bytes: PackedByteArray = input.to_byte_array()
	
	# Create a storage buffer that can hold our float values.
	_buffer = _rd.storage_buffer_create(input_bytes.size(), input_bytes)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(_buffer)
	_bindings.append(uniform)

func _create_texture_and_uniform(image: Image, format: RDTextureFormat, binding: int) -> RID:
	var view := RDTextureView.new()
	var data: PackedByteArray = image.get_data()
	var texture_id: RID = _rd.texture_create(format, view, [data])
	
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(texture_id)
	
	_bindings.append(uniform)
	return texture_id

func _texture_format(image: Image, one_byte: bool = false) -> RDTextureFormat:
	var format := RDTextureFormat.new()
	format.width = image.get_size().x
	format.height = image.get_size().y
	# Only really expecting 2 types of format
	format.format = (
		RenderingDevice.DATA_FORMAT_R8_UNORM
		if one_byte else
		RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM 
	)
	format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	)
	return format

func _prepare_texture_uniforms() -> void:
	var noise_image: Image = noise_texture.get_image()
	var noise_input_format: RDTextureFormat = _texture_format(noise_image, true)
	
	var base_image: Image = base_texture.get_image()
	var base_input_format: RDTextureFormat = _texture_format(base_image)
	 
	_image_size = noise_image.get_size()
	
	var output_image := Image.create(
		_image_size.x,
		_image_size.y,
		false, 
		Image.FORMAT_RGBA8
	)
	var output_format: RDTextureFormat = _texture_format(output_image)
	
	
	_noise_texure = _create_texture_and_uniform(noise_image, noise_input_format, 1)
	_base_texure = _create_texture_and_uniform(base_image, base_input_format, 2)
	_output_texure = _create_texture_and_uniform(output_image, output_format, 3)

func _apply_uniforms() -> void:
	_uniform_set = _rd.uniform_set_create(_bindings, _shader, 0)

func _create_compute_pipeline() -> void:
	# Create a compute pipeline
	var pipeline: RID = _rd.compute_pipeline_create(_shader)
	var compute_list: int = _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	_rd.compute_list_bind_uniform_set(compute_list, _uniform_set, 0)
	var groups_x : int = _image_size.x / _glsl_local_size.x
	var groups_y : int = _image_size.y / _glsl_local_size.y
	_rd.compute_list_dispatch(compute_list, groups_x, groups_y, _glsl_local_size.z)
	_rd.compute_list_end()

func _submit_to_gpu_and_sync() -> void:
	_rd.submit()
	_rd.sync()

func _extract_output_data() -> void:
	# Read back the data from the buffer
	var output_bytes : PackedByteArray = _rd.buffer_get_data(_buffer)
	var output : PackedFloat32Array = output_bytes.to_float32_array()
	print("Output: ", output)
	
	var image_bytes : PackedByteArray = _rd.texture_get_data(_output_texure, 0)
	var output_image: Image = Image.create_from_data(_image_size.x, _image_size.y, false, Image.FORMAT_RGBA8, image_bytes)
	_renderer.texture = ImageTexture.create_from_image(output_image)


func dispatch() -> void:
	await noise_texture.changed
	_create_local_rendering_device()
	_load_glsl_shader()
	_prepare_float_array_input_data()
	_prepare_texture_uniforms()
	_apply_uniforms()
	_create_compute_pipeline()
	_submit_to_gpu_and_sync()
	_extract_output_data()

#endregion

#region text tools

func _get_layout_from_glsl(path: String) -> Vector3i:
	var regex: RegEx = RegEx.create_from_string(r"layout\(local_size_x\s*=\s*(\d+)\s*,\s*local_size_y\s*=\s*(\d+)\s*,\s*local_size_z\s*=\s*(\d+)\s*\)")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var content: String = file.get_as_text()
	
	var result: RegExMatch = regex.search(content)
	
	return Vector3i(
		int(result.strings[1]),
		int(result.strings[2]),
		int(result.strings[3]),
	)

#endregion
