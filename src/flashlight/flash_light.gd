extends Node3D

const DRAIN_RATE: float = 12.0 # per second

@onready var crank: Node3D = $FlashlightModel/crank
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

func set_light() -> void:
	if (!is_light_blocked):
		if crank_meter < 50:
			spot_light_3d.light_energy = (crank_meter / 25.0)
		else:
			spot_light_3d.light_energy = lerpf(spot_light_3d.light_energy,4, 0.1)
	else:
		spot_light_3d.light_energy = 0

func flicker() -> void:
	if crank_meter != 0 and crank_meter <= 25 and flicker_cooldown.is_stopped():
		if randi() % 99 < 25:
			is_light_blocked = true
			flicker_cooldown.start()

func crank_flashlight(delta: float) -> void:
	if crank_meter >= 95: return
	
	crank_meter = min(100, crank_meter + 5)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		crank,
		"rotation:x",
		crank.rotation.x + deg_to_rad(190),
		1
	)

func _on_flicker_cooldown_timeout() -> void:
	is_light_blocked = false
