extends Area3D

const DIRT_FOOTSTEPS = preload("res://assets/sounds/dirt_footsteps.mp3")
const DIRT_FOOTSTEPS_RUN = preload("res://assets/sounds/dirt_footsteps_run.mp3")
const FLASHLIGHT_CLICK = preload("res://assets/sounds/flashlight_click.mp3")
const FLASHLIGHT_CRANK_SFX = preload("res://assets/sounds/flashlight_crank_sfx.mp3")
const AMBIENCE = preload("res://assets/sounds/freesound_community-night-woods-7012.mp3")
const JACK_IN_THE_BOX_MUSIC = preload("res://assets/sounds/jack_in_the_box_music.mp3")
const JACK_IN_THE_BOX_OPEN = preload("res://assets/sounds/jack_in_the_box_open.mp3")
@onready var player_ui: Control = $"../neck/Camera3D/HUD/SubViewport/PlayerUI"

@onready var refresh_area_timer: Timer = $RefreshAreaTimer
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var sounds = {
	DIRT_FOOTSTEPS: 10,
	DIRT_FOOTSTEPS_RUN: 20,
	FLASHLIGHT_CRANK_SFX: 20,
	JACK_IN_THE_BOX_MUSIC: 115,
}

#func _process(delta: float) -> void:
	#print(collision_shape_3d.shape.radius, collision_shape_3d.disabled)

func _ready() -> void:
	collision_shape_3d.disabled = true
	collision_shape_3d.shape.radius = 0.5

func add_sound(sound_file: Resource) -> void:
	if collision_shape_3d.shape.radius + sounds[sound_file] > 1:
		collision_shape_3d.disabled = false
		
	collision_shape_3d.shape.radius = min(collision_shape_3d.shape.radius + sounds[sound_file], 115)
	player_ui.set_sound_level(collision_shape_3d.shape.radius)
	
func remove_sound(sound_file: Resource) -> void:
	if !sounds: return
	if collision_shape_3d.shape.radius - sounds[sound_file] < 1:
		collision_shape_3d.disabled = true
		
	collision_shape_3d.shape.radius = max(collision_shape_3d.shape.radius - sounds[sound_file], 0.1)
	player_ui.set_sound_level(collision_shape_3d.shape.radius)
