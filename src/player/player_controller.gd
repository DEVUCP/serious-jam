extends CharacterBody3D


const SPEED = 3.0
const JUMP_VELOCITY = 4.5

signal camera_finished_transition

@export var is_in_tutorial: bool = false
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
#@export var MOUSE_SENSITIVITY : float = 0.5 
@export var INTERACT_RANGE : float = 3
@export var SPRINT_SPEED_FACTOR : float = 2.0
@export var STAMINA_PENALTY : float = 4.0
@export var STAMINA_COOLDOWN : float = STAMINA_PENALTY / 2

@onready var CAMERA_CONTROLLER = $neck/Camera3D
@onready var fire_ray = $neck/Camera3D/RayCast3D
@onready var hud = $neck/Camera3D/HUD
@onready var hand = $neck/Camera3D/Hand
@onready var footsteps = $Footsteps
@onready var cam = $neck/Camera3D
@onready var stamina_cooldown: Timer = $StaminaCooldown
@onready var flashlight: Node3D = $neck/Camera3D/Hand/Flashlight

@onready var stamina_bar_left: ProgressBar = $neck/Camera3D/HUD/SubViewport/PlayerUI/StaminaBar/StaminaBarLeft
@onready var stamina_bar_right: ProgressBar = $neck/Camera3D/HUD/SubViewport/PlayerUI/StaminaBar/StaminaBarRight
@onready var sound_area: Area3D = $SoundArea
@onready var player_ui: Control = $neck/Camera3D/HUD/SubViewport/PlayerUI


var _mouse_input : bool = false
var _stick_input: bool = false
var _mouse_rotation : Vector3
var _rotation_input : float 
var _tilt_input : float = 0.0
var _player_rotation : Vector3
var _camera_rotation : Vector3

var _cam_transition_pos : Vector3
var _cam_transition_rot : Vector3

var player_interactable_area
var notebook_toggled = false
var bobbing_up = true
var stamina : float = 100.0
var current_keys: int = 0
var is_immune: bool = false
var sprinting_toggled: bool = false
 
enum camera_transition_states{
	NO_TRANSITION,
	IN,
	OUT
}

enum input_capture_modes{ # all non "no cam" MUST use the camera (implied)
	PLAYER_CAPTURED,
	PLAYER_CAPTURED_NO_CAM,
	OBJECT_CAPTURED,
	OBJECT_CAPTURED_NO_CAM,
	DISABLED
}

var cam_transition_state = camera_transition_states.NO_TRANSITION
var input_capture : input_capture_modes = input_capture_modes.PLAYER_CAPTURED

func get_player_ui() -> Control:
	return player_ui

func take_key() -> void:
	$PickupSFX.play()
	current_keys +=1

func get_flashlight() -> Node3D:
	return flashlight

func get_sound_area() -> Node3D:
	return sound_area

func get_light_detection_factor() -> float:
	return flashlight.get_light_level() / 2.0

func is_input_allowed() -> bool:
	return input_capture == input_capture_modes.PLAYER_CAPTURED

func set_camera_transition_position(new_pos : Vector3) -> void:
	_cam_transition_pos = new_pos

func set_camera_transition_rotation(new_rot : Vector3) -> void:
	_cam_transition_rot = new_rot

func set_player_interactable_object(area) -> void:
	player_interactable_area = area

func fade_out() -> void:
	$neck/Camera3D/HUD/AnimationPlayer.play("camera_out")
	is_immune = true

func _attempt_interact_with_object() -> void:
	#print("interact attempt")
	if _is_there_interactable_object():
		#print("I SHOULD WORK")
		_interact_with_object()

func _interact_with_object() -> void:
	#print("player interact")
	#print(player_interactable_area.get_parent())
	player_interactable_area.interact(self)

func _is_there_interactable_object() -> bool:
	if player_interactable_area:
		if player_interactable_area.has_method("get_interactable"):
			#print(player_interactable_area.get_interactable())
			return player_interactable_area.get_interactable()
	return false

func enable_input_capture(take_cam : bool = true) -> void:
	var mode
	show_hand_item()
	if take_cam:
		mode = input_capture_modes.PLAYER_CAPTURED
		cam.current = true
	else:
		mode = input_capture_modes.PLAYER_CAPTURED_NO_CAM
	_set_input_capture_mode(mode)
	_cam_transition()

func disable_input_capture() -> void:
	_set_input_capture_mode(input_capture_modes.DISABLED)

func surrender_input_capture(take_cam : bool, cam_transition_pos: Vector3) -> void:
	var mode
	hide_hand_item()
	if take_cam:
		mode = input_capture_modes.OBJECT_CAPTURED 
	else:
		mode = input_capture_modes.OBJECT_CAPTURED_NO_CAM
	_set_input_capture_mode(mode)
	set_camera_transition_position(to_local(cam_transition_pos))
	#set_camera_transition_rotation(to_local(cam_transition_rot))
	_cam_transition()

func hide_hand_item() -> void:
	hand.visible = false

func show_hand_item() -> void:
	hand.visible = true

func _set_input_capture_mode(mode : input_capture_modes) -> void:
	input_capture = mode

func _on_interact_area_set_interactable_area(area: Area3D) -> void:
	set_player_interactable_object(area)
	#print(area.get_parent())

func _is_input_self_captured() -> bool:
	return input_capture == input_capture_modes.PLAYER_CAPTURED

func _is_sprinting_held() -> bool:
	return (Input.is_action_pressed("run") and 
	stamina >= 1 and 
	!Settings.toggle_sprint_setting and
	!Input.is_action_pressed("slow_walk") and 
	not Input.is_action_pressed("lean_left") and 
	not Input.is_action_pressed("lean_right"))

func _is_sprinting_and_toggled():
	return (Settings.toggle_sprint_setting and 
	sprinting_toggled and 
	stamina >= 1 and
	!Input.is_action_pressed("slow_walk") and 
	not Input.is_action_pressed("lean_left") and 
	not Input.is_action_pressed("lean_right"))

func _cam_transition() -> void:
	if is_input_allowed():
		cam_transition_state = camera_transition_states.OUT
		#$neck/Camera3D/HUD/AnimationPlayer.play("camera_in")
	else:
		#$neck/Camera3D/HUD/AnimationPlayer.play("camera_out")
		cam_transition_state = camera_transition_states.IN

func _input(event):
	if is_immune: return
	
	if !is_input_allowed():
		printerr("Player:_input -> Input not allowed")
		return
	if input_capture == input_capture_modes.OBJECT_CAPTURED_NO_CAM:
		return
	if !_is_input_self_captured():
		return
	
	if Input.is_action_just_pressed("run") and Settings.toggle_sprint_setting:
		get_viewport().set_input_as_handled()
		sprinting_toggled = !sprinting_toggled
	

	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input :
		_rotation_input = -event.relative.x * Settings.mouse_sens
		_tilt_input = -event.relative.y * Settings.mouse_sens
	
	var look
	if Input.get_connected_joypads():
		look = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		_rotation_input = -look.x * Settings.controller_sensitivity
		_tilt_input = -look.y * Settings.controller_sensitivity

func toggle_camera_capture(val : bool) -> void:
	CAMERA_CONTROLLER.current = val

func _update_camera(delta):
	if !is_input_allowed():
		printerr("Player:_update_cam -> Input not allowed")
		return
	if input_capture == input_capture_modes.OBJECT_CAPTURED_NO_CAM:
		return
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0,_mouse_rotation.y,0.0)
	_camera_rotation = Vector3(_mouse_rotation.x,0.0,0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0.0
	_tilt_input = 0.0

func _stamina_regen(delta: float) -> void:
	if stamina >= 99:
		stamina_bar_left.visible = false
		stamina_bar_right.visible = false
	
	if stamina_cooldown.is_stopped() and stamina <= 99:
		stamina = clamp(stamina + 15 * delta, 0, 100)
		_stamina_bar(0.09, delta)

func _stamina_deplete(delta: float) -> void:
	stamina_bar_left.visible = true
	stamina_bar_right.visible = true
	
	stamina = clamp(stamina - 15 * delta, 0, 100)
	if stamina <= 1:
		stamina_cooldown.start(STAMINA_PENALTY)
	else:
		stamina_cooldown.start(STAMINA_COOLDOWN)
	_stamina_bar(-0.09, delta)

func _stamina_bar(green_shift: float, delta: float) -> void:
	stamina_bar_left.value = stamina
	stamina_bar_right.value = stamina
	
	var current_color: Color = stamina_bar_left.get_theme_stylebox("fill").get("bg_color")
	var new_color = Color(current_color.r, clamp(current_color.g + green_shift * delta, 0, 255), current_color.b)
	
	stamina_bar_left.get_theme_stylebox("fill").set("bg_color", new_color)

func _sprint(run_speed: float, delta: float, is_moving: bool) -> float:
	if (_is_sprinting_held() or _is_sprinting_and_toggled()) and is_moving:
		run_speed = SPRINT_SPEED_FACTOR
		_stamina_deplete(delta)
		footsteps.set_stream(true)
	else:
		footsteps.set_stream(false)

	return run_speed

func _physics_process(delta: float) -> void:
	if is_immune: return
	
	if !is_input_allowed():
		#printerr("Player:_physics_process -> Input not allowed")
		return
	if input_capture == input_capture_modes.OBJECT_CAPTURED_NO_CAM:
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += (get_gravity() * 0.5) * delta

	var RUN_SPEED = 1
	_stamina_regen(delta)
	#print(stamina)
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	RUN_SPEED = _sprint(RUN_SPEED, delta, direction != Vector3.ZERO)
	if Input.is_action_pressed("slow_walk"):
		RUN_SPEED = 0.5
		
	if direction:
		velocity.x = direction.x * SPEED * RUN_SPEED 
		velocity.z = direction.z * SPEED * RUN_SPEED
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if input_dir.x > 0:
		$neck.rotation.z = lerp_angle($neck.rotation.z, deg_to_rad(-15), 0.05)
	elif input_dir.x < 0:
		$neck.rotation.z = lerp_angle($neck.rotation.z, deg_to_rad(15), 0.05)
	else:
		$neck.rotation.z = lerp_angle($neck.rotation.z, deg_to_rad(0), 0.05)
	

	

	var leaning = _handle_leaning()
	
	if (input_dir.y > 0 or input_dir.y < 0 or input_dir.x > 0 or input_dir.x < 0) and not leaning:
		if Input.is_action_pressed("slow_walk"):
			footsteps.call_deferred("stop_footstep")
		else:
			_handle_headbobbing(RUN_SPEED)
			footsteps.call_deferred("play_footstep")
	else:
		footsteps.call_deferred("stop_footstep")
	
	if(not leaning):
		move_and_slide()
		_update_camera(delta)

func _handle_headbobbing(run_speed):
	if $neck.position.y > 0.1 and bobbing_up:
		$neck.position.y = 0.1
		bobbing_up = false
	if $neck.position.y < 0.0 and not bobbing_up:
		$neck.position.y = 0.0
		bobbing_up = true
	
	var bob_speed = 0.05 * run_speed
	
	if bobbing_up:
		$neck.position.y = lerp($neck.position.y, 0.2, bob_speed)
	else:
		$neck.position.y = lerp($neck.position.y, -0.1, bob_speed)


func _handle_leaning() -> bool: 
	var lean_colliding_left = $LeanCollisionAreaLeft.get_colliding()
	var lean_colliding_right = $LeanCollisionAreaRight.get_colliding()
	if Input.is_action_pressed("lean_left") and not lean_colliding_left:
		$neck.rotation.z = lerp_angle($neck.rotation.z, deg_to_rad(45), 0.05)
		$neck.position.x = lerp($neck.position.x, -1.0, 0.1)
		
		$neck.rotation.x = lerp_angle($neck.rotation.x, deg_to_rad(0), 0.05)
		$neck.position.z = lerp($neck.position.z, 0.0, 0.1)
		
		return true
	elif Input.is_action_pressed("lean_right") and not lean_colliding_right:
		
		$neck.rotation.z = lerp_angle($neck.rotation.z, deg_to_rad(-45), 0.05)
		$neck.position.x = lerp($neck.position.x, 1.0, 0.1)
		
		$neck.rotation.x = lerp_angle($neck.rotation.x, deg_to_rad(0), 0.05)
		$neck.position.z = lerp($neck.position.z, 0.0, 0.1)
		
		return true
	else:
		$neck.rotation.z = lerp_angle($neck.rotation.z, deg_to_rad(0), 0.05)
		$neck.position.x = lerp($neck.position.x, 0.0, 0.1)
		
		$neck.rotation.x = lerp_angle($neck.rotation.x, deg_to_rad(0), 0.05)
		$neck.position.z = lerp($neck.position.z, 0.0, 0.1)
		
		return false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_rotation.y = rotation.y
	_mouse_rotation.x = CAMERA_CONTROLLER.rotation.x

func _process(delta: float) -> void:
	if is_immune: return

	
	if Input.is_action_pressed("interact"):
		#print("held")
		_attempt_interact_with_object()
	if cam_transition_state == camera_transition_states.IN:
		cam.position = lerp(cam.position, _cam_transition_pos, 0.05)
		var snapped_cam_pos = Vector3(snapped(cam.position.x,0.1), snapped(cam.position.y,0.1), snapped(cam.position.z,0.1))
		var snapped_target_pos = Vector3(snapped(_cam_transition_pos.x,0.1), snapped(_cam_transition_pos.y,0.1), snapped(_cam_transition_pos.z,0.1))

		if snapped_cam_pos == snapped_target_pos:
			cam_transition_state = camera_transition_states.NO_TRANSITION
			cam.position = _cam_transition_pos
			camera_finished_transition.emit()
			print('cam_finished_transition')
	elif cam_transition_state == camera_transition_states.OUT:
		cam.position = lerp(cam.position, Vector3(0.0,0.7,0.0), 0.1)
		var snapped_cam_pos = Vector3(snapped(cam.position.x,0.1), snapped(cam.position.y,0.1), snapped(cam.position.z,0.1))
		var snapped_target_pos = Vector3(0.0,0.7,0.0)

		if snapped_cam_pos == snapped_target_pos:
			cam_transition_state = camera_transition_states.NO_TRANSITION
			cam.position = Vector3(0,0.7,0)
			print('cam_finished_transition')
			camera_finished_transition.emit()
			

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "camera_out" and not is_in_tutorial:
		get_tree().change_scene_to_file("res://src/win_screen.tscn")
	elif is_in_tutorial:
		var loading_screen = preload("res://src/loading_screen.tscn").instantiate()
		loading_screen.scene_path_to_load = "res://src/main_menu.tscn"
		get_tree().root.add_child(loading_screen)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = loading_screen
