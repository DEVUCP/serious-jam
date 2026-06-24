extends SubViewportContainer
@onready var window_size = get_viewport().get_visible_rect().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	window_size = Vector2i(get_viewport().get_visible_rect().size)
	if window_size != $SubViewport.size:
		$SubViewport.size = window_size

func _ready() -> void:

	if OS.has_feature("web"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if OS.has_feature("web"):
		if event is InputEventMouseButton and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
