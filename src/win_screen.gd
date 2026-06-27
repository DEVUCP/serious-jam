extends Node3D

var spin_target = 3
var spin_counter = 0
@onready var camera_3d_2: Camera3D = $Camera3D2
@onready var camera_3d_3: Camera3D = $Camera3D3
@onready var camera_3d: Camera3D = $Camera3D

@onready var cams = [camera_3d_2, camera_3d_3, camera_3d]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


#func incr_counter() -> void:
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	$"Headspin Start2/AnimationPlayer2".play("mixamo_com")
	$AudioStreamPlayer3D.play()
	#print('ruh')
	$Timer.start((spin_target/1.5) * 0.8333)

func _on_timer_timeout() -> void:
	if spin_counter < spin_target:
		cams[spin_counter % 3].current = true
		spin_counter+=1
		$"Headspin Start2/AnimationPlayer2".play("mixamo_com")
		return
	$"Headspin Start2/AnimationPlayer3".play("mixamo_com")
	$Camera3D4.current = true

func _on_animation_player_3_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://src/main_menu.tscn")
