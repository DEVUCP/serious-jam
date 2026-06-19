extends Node3D

const MAX_ROTATION_SPEED: float = deg_to_rad(360) # degrees/sec
const DRAIN_RATE: float = 12.0 # per second

@onready var crank: MeshInstance3D = $Crank
@onready var spot_light_3d: SpotLight3D = $SpotLight3D
@onready var flicker_cooldown: Timer = $FlickerCooldown

var crank_meter: float = 0
var crank_rotation_target: float = 0.0
var is_light_blocked: bool = false

func _ready() -> void:
	spot_light_3d.light_energy = 0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Crank"):
		crank_flashlight(delta)
	crank_meter = max(crank_meter - DRAIN_RATE * delta, 0.0)

	set_light()

	flicker()
	
	print(crank_meter)
	print(is_light_blocked)

func set_light() -> void:
	if (!is_light_blocked):
		spot_light_3d.light_energy = (crank_meter / 25.0)
	else:
		spot_light_3d.light_energy = 0

func flicker() -> void:
	if crank_meter != 0 and crank_meter <= 25 and flicker_cooldown.is_stopped():
		if randi() % 99 < 25:
			is_light_blocked = true
			flicker_cooldown.start()

func crank_flashlight(delta: float) -> void:
	if crank_meter >= 90: return
	
	crank_meter = min(100, crank_meter + 5)
	crank_rotation_target += deg_to_rad(45)
	
	crank.rotation.x = move_toward(
		crank.rotation.x,
		crank_rotation_target,
		MAX_ROTATION_SPEED * delta
	)

func _on_flicker_cooldown_timeout() -> void:
	is_light_blocked = false
