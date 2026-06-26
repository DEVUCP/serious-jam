extends Node3D

var crank_meter: float = 0.0
var stopped_time: float = 0.0
var time_elapsed_paused: float = 0.0
@onready var crankoutline_2: Node3D = $InteractArea/CollisionShape3D/Outline/crankoutline2

@onready var crank_obj: Node3D = $blockbench_export/crank
@onready var crank_cooldown_timer: Timer = $CrankCooldownTimer
@onready var animation_player: AnimationPlayer = $blockbench_export/AnimationPlayer
@onready var music_sfx: SpatialAudioPlayer3D = $MusicSFX
@onready var key: Node3D = $Key
@onready var sound_area: Area3D = $SoundArea

const JACK_IN_THE_BOX_OPEN = preload("uid://chi30reeokeef")


@export var crank_target: int = 13.5
var playback_position: float = 0.0

func _on_interact_area_interacted_with(something: Variant) -> void:
	if crank_cooldown_timer.is_stopped():
		crank()
		crank_cooldown_timer.start()

func _physics_process(delta: float) -> void:
	_reverse_crank(delta)

func crank() -> void:
	if crank_meter >= crank_target:
		return
	
	_increase_crank_meter()
	_do_crank_tween()
	
	#if !music_sfx.is_playing():
		#music_sfx.play()
	#
	if !_resume_music() and !music_sfx.is_playing():
		music_sfx.play()
		sound_area.call_deferred("add_sound", music_sfx.stream)
	
	if crank_meter >= crank_target:
		_on_finished_crank_completion()


func _reverse_crank(delta) -> void:
	if crank_cooldown_timer.is_stopped() and crank_meter < crank_target and crank_meter > 0 and !Input.is_action_pressed("interact"):
		print("reversing crank")
		_deplete_crank_meter(delta)
		_do_reverse_tween()
		_set_stopped_time()
		_count_elapsed(delta)

func _resume_music() -> bool:
	if floor(stopped_time) and !music_sfx.is_playing():
		print('resumed')
		music_sfx.seek(clampf(stopped_time - time_elapsed_paused, 0, stopped_time))
		stopped_time = 0
		time_elapsed_paused = 0
		return true
	return false

func _set_stopped_time() -> void:
	if floor(stopped_time):
		return
	#print(stopped_time)
	stopped_time = music_sfx.get_playback_position()
	music_sfx.stop()
	sound_area.call_deferred("remove_sound", music_sfx.stream)

func _count_elapsed(delta) -> void:
	time_elapsed_paused += delta

func _deplete_crank_meter(delta) -> void:
	crank_meter = clamp(crank_meter-0.7 * delta, 0, 100)

func _increase_crank_meter() -> void:
	crank_meter = min(crank_meter +  0.07 , crank_target)

func _do_reverse_tween() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		crank_obj,
		"rotation:x",
		crank_obj.rotation.x - deg_to_rad(70),
		1
	)
	var tween_outline = create_tween()
	tween_outline.set_ease(Tween.EASE_OUT)
	tween_outline.set_trans(Tween.TRANS_SINE)
	tween_outline.tween_property(
		crankoutline_2,
		"rotation:x",
		crankoutline_2.rotation.x - deg_to_rad(70),
		1
	)

func _do_crank_tween() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		crank_obj,
		"rotation:x",
		crank_obj.rotation.x + deg_to_rad(90),
		0.7
	)
	var outlinetween = create_tween()
	outlinetween.set_ease(Tween.EASE_OUT)
	outlinetween.set_trans(Tween.TRANS_SINE)
	outlinetween.tween_property(
		crankoutline_2,
		"rotation:x",
		crankoutline_2.rotation.x + deg_to_rad(90),
		0.7
	)

func _on_finished_crank_completion() -> void:
	animation_player.play("open")
	music_sfx.stop()
	sound_area.call_deferred("remove_sound", music_sfx.stream)
	music_sfx.stream = JACK_IN_THE_BOX_OPEN
	music_sfx.play()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "open": return
	key.visible = true
	key.get_child(2).monitoring = true
	key.get_child(2).monitorable = true
	


func _on_interact_area_area_entered(area: Area3D) -> void:
	$InteractArea/CollisionShape3D/Outline.visible = true



func _on_interact_area_area_exited(area: Area3D) -> void:
	$InteractArea/CollisionShape3D/Outline.visible = false
