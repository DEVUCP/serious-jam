extends Node3D
#
#var creaky_sfx = preload("res://assets/sfx/creaky_floor_new.ogg")
#var concrete_sfx = preload("res://assets/sfx/concrete_footsteps.mp3")
var dirt_sfx = preload("res://assets/sounds/dirt_footsteps.mp3")
var dirt_sprinting_sfx = preload("res://assets/sounds/dirt_footsteps_run.mp3")

@onready var footsteps_player = $SpatialAudioPlayer3D
@onready var floor_ray = $RayCast3D
var is_sprinting = false


func set_is_sprinting(new_val : bool) -> void:
	is_sprinting = new_val

func set_stream(sprinting : bool) -> void:
	if sprinting and footsteps_player.stream != dirt_sprinting_sfx:
		footsteps_player.set_stream(dirt_sprinting_sfx)
		print("set running")
		return
	if !sprinting and footsteps_player.stream != dirt_sfx:
		footsteps_player.set_stream(dirt_sfx)
		print("set walking")
		return

func play_footstep() -> void:
	if !floor_ray.is_colliding():
		footsteps_player.stop()
		return
	var floor = floor_ray.get_collider().name
	
	if not footsteps_player.playing:
		footsteps_player.play()
	#print(floor)
	#match floor:
		#"wood":
			#if footsteps_player.stream != creaky_sfx or not footsteps_player.playing:
				#footsteps_player.set_stream(creaky_sfx)
				#footsteps_player.play()
		#"Terrain3D":
			#if footsteps_player.stream != dirt_sfx or not footsteps_player.playing:
				#footsteps_player.set_stream(dirt_sfx)
				#footsteps_player.play()
		#"Concrete":
			#if footsteps_player.stream != concrete_sfx or not footsteps_player.playing:
				#footsteps_player.set_stream(concrete_sfx)
				#footsteps_player.play()

func stop_footstep() -> void:
	footsteps_player.stop()
