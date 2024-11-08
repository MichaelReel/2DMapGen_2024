class_name GLSLBufferOutput
extends GLSLResource

var output_buffer_bytes_size: int
var bytes: PackedByteArray

func _init(output_buffer_bytes_size: int, binding: int) -> void:
	self.output_buffer_bytes_size = output_buffer_bytes_size
	self.binding = binding
