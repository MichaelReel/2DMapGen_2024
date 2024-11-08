class_name BaseDispatcher
extends Node

signal computation_complete

var glsl_buffer_inputs: Array[GLSLBufferInput] = []
var glsl_buffer_outputs: Array[GLSLBufferOutput] = []
@export var glsl_texture_inputs: Array[GLSLTextureInput] = []
@export var glsl_texture_outputs: Array[GLSLTextureOutput] = []
@export_group("Base Requirements")
@export_file("*.glsl") var _compute_shader: String

var _rd: RenderingDevice
var _glsl_local_size: Vector3i 
var _shader: RID
var _uniform_set : RID
var _bindings: Array[RDUniform] = []
var _image_range: Vector2i = Vector2i.ZERO

##region DISPATCH STEPS

func _create_local_rendering_device() -> void:
	_rd = RenderingServer.create_local_rendering_device()
	if not _rd:
		set_process(false)
		push_error("Compute shaders are not available")

func _load_glsl_shader() -> void:
	_glsl_local_size = _get_layout_from_glsl(_compute_shader)
	
	var shader_file: RDShaderFile = load(_compute_shader) as RDShaderFile
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	_shader = _rd.shader_create_from_spirv(shader_spirv)

func _update_image_size_range(image_size: Vector2i) -> void:
	_image_range.x = max(_image_range.x, image_size.x)
	_image_range.y = max(_image_range.y, image_size.y)

func _prepare_input_buffer_uniform(buffer_input: GLSLBufferInput) -> void:
	buffer_input.rid = _rd.storage_buffer_create(buffer_input.bytes.size(), buffer_input.bytes)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = buffer_input.binding
	uniform.add_id(buffer_input.rid)
	_bindings.append(uniform)
	print(uniform.binding, ":", _bindings)

func _prepare_input_buffer_uniforms() -> void:
	for buffer_input: GLSLBufferInput in glsl_buffer_inputs:
		_prepare_input_buffer_uniform(buffer_input)

func _prepare_input_texture_uniform(texture_input: GLSLTextureInput) -> void:
	# If our input happends to be a noise texture, we need to let it render
	var noise_texture: NoiseTexture2D = texture_input.texture as NoiseTexture2D
	if noise_texture:
		print("Start Await")
		await noise_texture.changed
		print("Await Done")
	
	# Grab image data
	var input_image: Image = texture_input.texture.get_image()
	var input_format: RDTextureFormat = RDTextureFormat.new()
	input_format.width = input_image.get_size().x
	input_format.height = input_image.get_size().y
	input_format.format = texture_input.data_format
	input_format.usage_bits = texture_input.usage_bits
	
	# Check the range is updated
	_update_image_size_range(input_image.get_size())
	
	# Load into memory
	var view := RDTextureView.new()
	var data: PackedByteArray = input_image.get_data()
	texture_input.rid = _rd.texture_create(input_format, view, [data])
	
	# Add to uniforms
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = texture_input.binding
	uniform.add_id(texture_input.rid)
	_bindings.append(uniform)
	print(uniform.binding, ":", _bindings)

func _prepare_input_texture_uniforms() -> void:
	for texture_input: GLSLTextureInput in glsl_texture_inputs:
		await _prepare_input_texture_uniform(texture_input)

func _prepare_output_buffer_uniform(buffer_output: GLSLBufferOutput) -> void:
	# Give the output some memory to use
	var output_memory: PackedByteArray = PackedByteArray()
	output_memory.resize(buffer_output.output_buffer_bytes_size)
	buffer_output.rid = _rd.storage_buffer_create(output_memory.size(), output_memory)
	
	# Create a uniform to assign the buffer to the rendering device
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = buffer_output.binding
	uniform.add_id(buffer_output.rid)
	_bindings.append(uniform)
	print(uniform.binding, ":", _bindings)

func _prepare_output_buffer_uniforms() -> void:
	for buffer_output: GLSLBufferOutput in glsl_buffer_outputs:
		_prepare_output_buffer_uniform(buffer_output)

func _prepare_output_texture_uniform(texture_output: GLSLTextureOutput) -> void:
	var output_image := Image.create(
		texture_output.size.x,
		texture_output.size.y,
		false, 
		texture_output.image_format,
	)
	var output_format: RDTextureFormat = RDTextureFormat.new()
	output_format.width = output_image.get_size().x
	output_format.height = output_image.get_size().y
	output_format.format = texture_output.data_format 
	output_format.usage_bits = texture_output.usage_bits
	
	# Check the range is updated
	_update_image_size_range(texture_output.size)
	
	# Load into memory
	var view := RDTextureView.new()
	var data: PackedByteArray = output_image.get_data()
	texture_output.rid = _rd.texture_create(output_format, view, [data])
	
	# Add to uniforms
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = texture_output.binding
	uniform.add_id(texture_output.rid)
	_bindings.append(uniform)
	print(uniform.binding, ":", _bindings)

func _prepare_output_texture_uniforms() -> void:
	for texture_output: GLSLTextureOutput in glsl_texture_outputs:
		_prepare_output_texture_uniform(texture_output)

func _apply_uniforms() -> void:
	print(_bindings)
	_uniform_set = _rd.uniform_set_create(_bindings, _shader, 0)

func _create_compute_pipeline() -> void:
	# Create a compute pipeline
	var pipeline: RID = _rd.compute_pipeline_create(_shader)
	var compute_list: int = _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	_rd.compute_list_bind_uniform_set(compute_list, _uniform_set, 0)
	var groups_x : int = _image_range.x / _glsl_local_size.x
	var groups_y : int = _image_range.y / _glsl_local_size.y
	_rd.compute_list_dispatch(compute_list, groups_x, groups_y, _glsl_local_size.z)
	_rd.compute_list_end()

func _submit_to_gpu_and_sync() -> void:
	_rd.submit()
	_rd.sync()

func _extract_output_buffers() -> void:
	for buffer_output: GLSLBufferOutput in glsl_buffer_outputs:
		var output_bytes: PackedByteArray = _rd.buffer_get_data(buffer_output.rid)
		buffer_output.bytes = output_bytes

func _extract_output_images() -> void:
	for texture_output: GLSLTextureOutput in glsl_texture_outputs:
		var image_bytes : PackedByteArray = _rd.texture_get_data(texture_output.rid, 0)
		var output_image: Image = Image.create_from_data(
			texture_output.size.x,
			texture_output.size.y,
			false,
			texture_output.image_format,
			image_bytes,
		)
		texture_output.output_texture = ImageTexture.create_from_image(output_image)

func _clean_up() ->void:
	for texture_output: GLSLTextureOutput in glsl_texture_outputs:
		_rd.free_rid(texture_output.rid)
	for buffer_output: GLSLBufferOutput in glsl_buffer_outputs:
		_rd.free_rid(buffer_output.rid)
	for texture_input: GLSLTextureInput in glsl_texture_inputs:
		_rd.free_rid(texture_input.rid)
	for buffer_input: GLSLBufferInput in glsl_buffer_inputs:
		_rd.free_rid(buffer_input.rid)
	_rd.free_rid(_shader)

func base_dispatch() -> void:
	if not _compute_shader:
		push_error("Don't forget to configure a shader.")
		return
	
	## Do the pipeline
	_create_local_rendering_device()
	_load_glsl_shader()
	_prepare_input_buffer_uniforms()
	await _prepare_input_texture_uniforms()
	_prepare_output_buffer_uniforms()
	_prepare_output_texture_uniforms()
	
	_apply_uniforms()
	_create_compute_pipeline()
	_submit_to_gpu_and_sync()
	_extract_output_buffers()
	_extract_output_images()
	_clean_up()
	computation_complete.emit()

##endregion

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
