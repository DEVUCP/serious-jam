class_name InteractArea
extends Area3D
signal interacted_with(something)

var interactable = true

func set_interactable(val : bool) -> void:
	interactable = val

func get_interactable() -> bool:
	return interactable


func interact(something : Variant = null) -> void:
	emit_signal("interacted_with", something)
