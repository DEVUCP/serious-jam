extends SubViewportContainer
@onready var window_size = get_viewport().get_visible_rect().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	window_size = Vector2i(get_viewport().get_visible_rect().size)
	if window_size != $SubViewport.size:
		$SubViewport.size = window_size

#
#func _input(event):
	## Manually push the event into the subviewport
	#$SubViewport.push_input(event)


func _ready() -> void:

	if OS.has_feature("web"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#message_timer.timeout.connect(func(): message_label.text = "")



#func _unhandled_input(event: InputEvent) -> void:
	#$SubViewport.push_input(event)
	#if OS.has_feature("web") and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and event is InputEventMouseButton and event.pressed:
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#get_viewport().set_input_as_handled()
		#return
