extends Node3D

var crank_meter: float = 0.0

@onready var crank_obj: Node3D = $blockbench_export/crank
@onready var crank_cooldown_timer: Timer = $CrankCooldownTimer
@onready var animation_player: AnimationPlayer = $blockbench_export/AnimationPlayer

@export var crank_target: int = 5

func _on_interact_area_interacted_with(something: Variant) -> void:
	if crank_cooldown_timer.is_stopped():
		crank()
		crank_cooldown_timer.start()

func _physics_process(delta: float) -> void:
	#print(crank_meter)
	if crank_cooldown_timer.is_stopped() and crank_meter < crank_target and crank_meter > 0:
		var tween = create_tween()
		crank_meter = clamp(crank_meter-0.7 * delta, 0, 100)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(
		crank_obj,
		"rotation:x",
		crank_obj.rotation.x - deg_to_rad(70),
		1
	)

func crank() -> void:
	if crank_meter >= crank_target:
		return
	
	crank_meter = min(crank_meter +  0.07 , crank_target)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		crank_obj,
		"rotation:x",
		crank_obj.rotation.x + deg_to_rad(90),
		0.7
	)

	if crank_meter >= crank_target:
		_on_finished_crank_completion()

func _on_finished_crank_completion() -> void:
	animation_player.play("open")
