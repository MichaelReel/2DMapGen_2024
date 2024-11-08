extends TextureRect

@onready var dispatcher: Node = %ZonedIslandDispatcher

func _ready() -> void:
	if dispatcher.has_method("dispatch"):
		dispatcher.call("dispatch")
	else:
		push_error("Dispatcher doesn't exist or has no dispatch function")
