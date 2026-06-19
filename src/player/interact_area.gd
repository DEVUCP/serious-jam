extends Area3D

signal set_interactable_area(area)

func _on_area_entered(area: Area3D) -> void:
	if is_area_interactable(area):
		emit_signal("set_interactable_area",area)

func _on_area_exited(area: Area3D) -> void:
	if is_area_interactable(area):
		emit_signal("set_interactable_area",null)

func is_area_interactable(area : Area3D) -> bool:
	if area.has_method("get_interactable"):
		return area.get_interactable()
	return false
