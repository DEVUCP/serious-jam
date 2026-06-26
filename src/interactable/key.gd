extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_area_interacted_with(something: Variant) -> void:
	something.call_deferred("take_key")
	#await get_tree().create_timer(1).timeout
	self.call_deferred("queue_free")


func _on_interact_area_area_entered(area: Area3D) -> void:
	if area.get_parent().name == "MusicBox": return

	$outline.visible = true


func _on_interact_area_area_exited(area: Area3D) -> void:
	$outline.visible = false
