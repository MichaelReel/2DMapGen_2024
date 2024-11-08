class_name GLSLBufferInput
extends GLSLResource

var bytes: PackedByteArray = PackedByteArray()

func _init(bytes: PackedByteArray, binding: int) -> void:
	self.bytes = bytes
	self.binding = binding
