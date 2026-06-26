extends Label3D

func _ready() -> void:
	visible = false

func _on_area_3d_body_entered(body: Node3D) -> void:
	visible = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	visible = false
