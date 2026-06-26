extends CharacterBody3D

@export var player_path: NodePath
@export var nav_region_path: NodePath
@export var view_range: float = 160.0
@export var detection_range: float = 25.0
@export var agro_range: float = detection_range / 2.0
@export var investigate_range: float = 5
@export var light_detection_tolerence: float = 1.0

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var investigating_cooldown: Timer = $InvestigatingCooldown
@onready var footstep_sfx: SpatialAudioPlayer3D = $FootstepSFX
@onready var monkey_sounds: SpatialAudioPlayer3D = $MonkeySounds
@onready var roaming_sfx_timer: Timer = $RoamingSFXTimer
@onready var animation_player: AnimationPlayer = $EnemyModel/AnimationPlayer

const SPEED: float = 195.0
var investigating_sfx: Resource = preload("res://assets/sounds/monkey_investigate.mp3")
var screech_sfx: Resource = preload("res://assets/sounds/monkey_screech.mp3")
var roaming_sfx: Resource = preload("res://assets/sounds/monkey_roaming.mp3")
var dirt_sfx: Resource = preload("res://assets/sounds/dirt_footsteps.mp3")
var dirt_sprinting_sfx: Resource = preload("res://assets/sounds/dirt_footsteps_run.mp3")

var player: CharacterBody3D = null
var nav_region: NavigationRegion3D = null
var target_pos: Vector3
var investigation_positions = []
var sprint_factor: float = 1.0

enum states {
	roaming,
	investigating,
	chasing
}

var state: states

func set_state(new_state : states) -> void:
	state = new_state

func _ready() -> void:
	randomize()
	initialize_ai()
	
	$DefaultEnemyModel.visible = false

## Initilizes [member player], [member nav_region], [member ray_cast_3d.target_position.z] and sets initial [member state] to [member states.ROAMING]
func initialize_ai() -> void:
	player = get_node(player_path)
	nav_region = get_node(nav_region_path)
	
	ray_cast_3d.target_position.z = -detection_range
	
	update_state(states.roaming)

## Sets new state and Calls [method do_state_action]
func update_state(new_state: states) -> void:
	set_state(new_state)
	do_state_action()


func _physics_process(delta: float) -> void:
	#print(states.keys()[state])
	
	if player.is_immune: return
	
	velocity = Vector3.ZERO
	if animation_player.current_animation == "investigating":
		return
	_looking()
	_update_detection_range()
	
	if _is_player_detected():
		_on_player_detected()
		
	if target_pos == Vector3.ZERO: 
		do_state_action()
		return
	
	var next_nav_point = _handle_movement(delta)
	_face_move_direction(next_nav_point)
	_do_footstep_sounds()
	if (velocity.x > 0.2 or velocity.z > 0.2) and !animation_player.is_playing():
		animation_player.play("running")
	move_and_slide()

## Handles movement of body to next poisition 
## Returns a [Vector3] next_nav_point
func _handle_movement(delta) -> Vector3:
	var map_rid: RID = get_world_3d().get_navigation_map()
	var closest_point = NavigationServer3D.map_get_closest_point(map_rid, target_pos)
	navigation_agent_3d.set_target_position(closest_point)
	
	var next_nav_point = navigation_agent_3d.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * SPEED * sprint_factor * delta
	return next_nav_point

## Rotates body to look at where its moving by modifying [member basis]
func _face_move_direction(next_nav_point : Vector3) -> void:
	var direction: Vector3 = global_position.direction_to(next_nav_point)
	var target_basis: Basis = Basis.looking_at(direction, Vector3.UP)
	
	basis = basis.slerp(target_basis, 0.1)

func _do_footstep_sounds() -> void:
	if velocity and !footstep_sfx.playing:
		footstep_sfx.play()

func _update_footstep_sounds(sound_file : Resource) -> void:
	if footstep_sfx.stream != sound_file:
		footstep_sfx.stream = sound_file

func _update_detection_range() -> void:
	var light_detection_factor = player.get_light_detection_factor()
	var aggro_factor = 1
	if state != states.roaming:
		aggro_factor = 1.25
	
	detection_range = 15.0 + (15 * light_detection_factor)
	agro_range = (detection_range / 1.5)  * aggro_factor
	
	ray_cast_3d.target_position.z = -detection_range

func _is_in_agro_range() -> bool:
	return global_position.distance_to(player.global_position) < agro_range

func _on_player_detected() -> void:
	if _is_in_agro_range():
		if state == states.chasing: return
		update_state(states.chasing)
	else:
		if state == states.investigating: return
		_initiate_investigation()
		update_state(states.investigating)

func _initiate_investigation() -> void:
	if !investigating_cooldown.is_stopped(): return
	
	investigation_positions.clear()
	var last_known_player_location = player.global_position
	for i in range(3):
		randomize()
		investigation_positions.append(last_known_player_location + Vector3(randf_range(-investigate_range, investigate_range), 0, randf_range(-investigate_range, investigate_range)))

func _is_player_detected() -> bool:
	return ray_cast_3d.is_colliding() && ray_cast_3d.get_collider() == player

## Points raycast to player if they are in the view angle (fov)
func _looking() -> void:
	var to_player = (player.global_transform.origin - global_transform.origin).normalized()
	var forward = -global_transform.basis.z
	var angle_deg = rad_to_deg(acos(clamp(forward.dot(to_player), -1.0, 1.0)))
	if angle_deg > view_range * 0.5:
		return
	
	# Point raycast to player if in view_angle (fov)
	var target = player.global_position + Vector3.UP * 0.5
	ray_cast_3d.look_at(target, Vector3.UP) 

## Sets target position to a random point on the map
func roam():
	_update_footstep_sounds(dirt_sfx)
	set_sprint_factor()
	target_pos = get_random_nav_point()

func _play_state_sound(sound_file :Resource) -> void:
	#print(sound_file)
	if sound_file == monkey_sounds.stream and monkey_sounds.playing: return
	monkey_sounds.stop()
	monkey_sounds.stream = sound_file
	monkey_sounds.play()

func investigate():
	_update_footstep_sounds(dirt_sfx)
	_play_state_sound(investigating_sfx)
	set_sprint_factor(2)
	if is_done_investigating():
		update_state(states.roaming)
		return
	_update_investigation_point()

## If [member investigating_cooldown] is done, updates [member target_pos] to the next [member investigation_positions], otherwise it will set it to [code]Vector3.ZERO[/code]
func _update_investigation_point() -> void:
	if investigating_cooldown.is_stopped():
		target_pos = investigation_positions.pop_front()
		$MeshInstance3D3.global_position = target_pos
		investigating_cooldown.start()
		print("INVESTIGATING AT ", target_pos)
	else:
		target_pos = Vector3.ZERO

func is_done_investigating() -> bool:
	return investigation_positions.size() == 0

# Sets target position to the players position
func chase():
	_update_footstep_sounds(dirt_sprinting_sfx)
	_play_state_sound(screech_sfx)
	_update_detection_range()
	set_sprint_factor(1.5)
	target_pos = player.global_position

func get_random_nav_point(
	center: Vector3 = Vector3.ZERO,
	_range: float = -1.0
) -> Vector3:
	var navmesh: NavigationMesh = nav_region.navigation_mesh
	
	for i in 50:
		var poly_index = randi() % navmesh.get_polygon_count()
		var poly = navmesh.get_polygon(poly_index)
		
		var vertex_index = poly[randi() % poly.size()]
		var point = nav_region.to_global(navmesh.vertices[vertex_index])
		
		if _range < 0.0 or point.distance_to(center) <= _range:
			return point
	
	return center

## Sets [member sprint_factor], defaults to [code]1.0[/code] if no argument given
func set_sprint_factor(new_val : float = 1.0) -> void:
	sprint_factor = new_val

## Runs the corresponding function based on state
func do_state_action():
	match state:
		states.roaming:
			roam()
		states.investigating:
			investigate()
		states.chasing:
			chase()

func _on_navigation_agent_3d_target_reached() -> void:
	if state == states.investigating:
		animation_player.stop()
		animation_player.play("investigating")
	do_state_action()

func _on_light_detection_area_area_entered(area: Area3D) -> void:
	if player.get_flashlight().get_light_level() < light_detection_tolerence: return
	_is_player_lighting_me()


func _is_player_lighting_me() -> void:
	var raycast: RayCast3D = RayCast3D.new()
	add_child(raycast)
	raycast.set_collision_mask_value(1, false)
	raycast.set_collision_mask_value(3, true)
	raycast.target_position = to_local(player.global_position)
	
	if raycast.is_colliding():
		raycast.call_deferred("queue_free")
	
	update_state(states.chasing)
	raycast.call_deferred("queue_free")

func _on_roaming_sfx_timer_timeout() -> void:
	if state == states.roaming:
		_play_state_sound(roaming_sfx)

func _on_jumpscare_area_body_entered(body: Node3D) -> void:
	if body != player: return
	print(body)
	$AnimationPlayer.play("jump_scare")
	body.is_immune = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "jump_scare": return
	
	get_tree().reload_current_scene()
