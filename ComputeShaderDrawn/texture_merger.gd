extends TextureRect

@onready var dispatcher: Node = %Dispatcher

func _ready() -> void:
	if dispatcher.has_method("dispatch"):
		dispatcher.call("dispatch")
	else:
		printerr("Dispatcher doesn't exist or has no dispatch function")
