extends Node3D

const DRAIN_RATE: float = 12.0 # per second

@onready var crank: Node3D = $FlashlightModel/crank
@onready var spot_light_3d: SpotLight3D = $SpotLight3D
@onready var flicker_cooldown: Timer = $FlickerCooldown
@onready var flashlight_collision: Area3D = $FlashlightCollision
@onready var crank_sfx: SpatialAudioPlayer3D = $CrankSFX
@onready var crank_cooldown: Timer = $CrankCooldown
@onready var flicker_sfx: SpatialAudioPlayer3D = $FlickerSFX
@onready var sound_area: Area3D = get_parent().get_parent().get_parent().get_parent().get_child(10)

var crank_meter: float = 0
var crank_rotation_target: float = 0.0
var is_light_blocked: bool = false

func _ready() -> void:
	spot_light_3d.light_energy = 0
	const LAYER_1 = 1 << 0
	const LAYER_2 = 1 << 1
	const LAYER_32 = 1 << 31

	$AreaLight3D.light_cull_mask = ~(LAYER_2 | LAYER_32 | LAYER_1)

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
			spot_light_3d.light_energy = lerpf(spot_light_3d.light_energy, 4, 0.1)
	else:
		spot_light_3d.light_energy = 0
	
	flashlight_collision.set_collision_layer_value(4, !flashlight_collision.get_collision_layer_value(4))
	
func get_light_level() -> float:
	return spot_light_3d.light_energy

func flicker() -> void:
	if crank_meter != 0 and crank_meter <= 25 and flicker_cooldown.is_stopped():
		if randi() % 99 < 25:
			is_light_blocked = true
			flicker_cooldown.start()
			flicker_sfx.play()
			if crank_meter <= 5:
				flicker_sfx.stop()

func crank_flashlight(delta: float) -> void:
	if crank_meter >= 95: return
	crank_meter = min(100, crank_meter + 5)
	
	if crank_cooldown.is_stopped():
		crank_sfx.play()
		sound_area.call_deferred("add_sound", crank_sfx.stream)

	crank_cooldown.start()

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


func _on_crank_cooldown_timeout() -> void:
	sound_area.call_deferred("remove_sound", crank_sfx.stream)	
	crank_sfx.stop()
