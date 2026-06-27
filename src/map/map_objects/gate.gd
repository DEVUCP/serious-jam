extends Node3D

@onready var interact_timer: Timer = $InteractTimer
@onready var locks: Node3D = $Locks

func _on_interact_area_interacted_with(something: Variant) -> void:
	if !interact_timer.is_stopped(): return
	interact_timer.start()
	var current_keys: int = something.current_keys
	
	if current_keys <= 0: return
	while current_keys > 0:
		if locks.get_child(current_keys - 1).freeze == true:
			locks.get_child(current_keys - 1).freeze = false
		current_keys -= 1
	$LockSFX.play()
	
	if something.current_keys == locks.get_child_count():
		$blockbench_export/Node3D.rotate_y(-90)
		something.fade_out()
