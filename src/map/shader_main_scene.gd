extends SubViewportContainer
@export var main_menu: bool = false
@onready var window_size = get_viewport().get_visible_rect().size
@export var tutorial: bool = false
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	window_size = Vector2i(get_viewport().get_visible_rect().size)
	if window_size != $SubViewport.size:
		$SubViewport.size = window_size

func _ready() -> void:
	if main_menu:
		await get_tree().process_frame
		await get_tree().process_frame
		$SubViewport.size = get_viewport().get_visible_rect().size
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if OS.has_feature("web"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().process_frame
	if !tutorial:
		var map = preload("res://src/map/map.tscn").instantiate()
		$SubViewport/Node3D.add_child(map)

func _input(event):
	if main_menu:
		return
	if OS.has_feature("web"):
		if event is InputEventMouseButton and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
