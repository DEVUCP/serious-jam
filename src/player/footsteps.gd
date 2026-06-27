extends Node3D
#
#var creaky_sfx = preload("res://assets/sfx/creaky_floor_new.ogg")
#var concrete_sfx = preload("res://assets/sfx/concrete_footsteps.mp3")
var dirt_sfx = preload("res://assets/sounds/dirt_footsteps.mp3")
var dirt_sprinting_sfx = preload("res://assets/sounds/dirt_footsteps_run.mp3")

@onready var footsteps_player = $SpatialAudioPlayer3D
@onready var floor_ray = $RayCast3D
@onready var sound_area: Area3D = $"../SoundArea"

var is_sprinting = false

func set_is_sprinting(new_val : bool) -> void:
	is_sprinting = new_val

func set_stream(sprinting : bool) -> void:
	if sprinting and footsteps_player.stream != dirt_sprinting_sfx:
		stop_footstep()
		footsteps_player.set_stream(dirt_sprinting_sfx)
		#print("set running")
		return
	if !sprinting and footsteps_player.stream != dirt_sfx:
		stop_footstep()
		footsteps_player.set_stream(dirt_sfx)
		#print("set walking")
		return

func play_footstep() -> void:
	#if !floor_ray.is_colliding():
		#stop_footstep()
		#return
	
	if not footsteps_player.playing:
		footsteps_player.play()
		sound_area.call_deferred("add_sound", footsteps_player.stream)

func stop_footstep() -> void:
	if !footsteps_player.playing: return
	#print("stopped x")
	sound_area.call_deferred("remove_sound", footsteps_player.stream)
	footsteps_player.stop()


func _on_spatial_audio_player_3d_finished() -> void:
	sound_area.call_deferred("remove_sound", footsteps_player.stream)
