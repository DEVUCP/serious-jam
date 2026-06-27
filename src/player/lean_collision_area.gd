extends Area3D
@export var colliding = false
var colliding_counter = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func set_colliding(new_val: bool) -> void:
	colliding = new_val

func get_colliding() -> bool:
	return colliding

func attempt_set_colliding(new_val : bool) -> void:
	if not new_val:
		if colliding_counter:
			return
	set_colliding(new_val)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	colliding_counter += 1
	set_colliding(true)
	#print('LOLLL')


func _on_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	colliding_counter -=1
	attempt_set_colliding(false)
