extends Node3D

var crank_meter: float = 0.0

@onready var crank_obj: MeshInstance3D = $Crank

@export var crank_target: int = 3

func _on_interact_area_interacted_with(something: Variant) -> void:
	crank()

func crank() -> void:
	if crank_meter >= crank_target:
		return
	
	crank_meter = min(crank_meter + 1, crank_target)
	
	var tween = create_tween()
	tween.tween_property(
		crank_obj,
		"rotation:x",
		crank_obj.rotation.x + deg_to_rad(65),
		0.3
	)

	if crank_meter >= crank_target:
		print("Done!")
