class_name GLSLTextureOutput
extends GLSLResource

@export var data_format: RenderingDevice.DataFormat = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
@export var image_format: Image.Format = Image.FORMAT_RGBA8
@export var size: Vector2i
@export var usage_bits: int = (
	RenderingDevice.TEXTURE_USAGE_STORAGE_BIT |
	RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT |
	RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
)
@export var output_texture: Texture2D
