extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var width := int(size.x)
	var height := int(size.y)

	# Configure noise
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = 0.01
	noise.fractal_octaves = 4
	noise.fractal_gain = 1.1

	var noiseImage: Image = noise.get_image(width, height)

	var imageTexture: ImageTexture = ImageTexture.create_from_image(noiseImage)
	self.texture = imageTexture
	
	imageTexture.resource_name = "The created texture!"
	print(self.texture.resource_name)
