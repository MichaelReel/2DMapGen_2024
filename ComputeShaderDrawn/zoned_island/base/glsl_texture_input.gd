class_name GLSLTextureInput
extends GLSLResource

@export var texture: Texture2D
@export var data_format: RenderingDevice.DataFormat = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
@export var usage_bits: int = (
	RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
	RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |
	RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
)
