extends CharacterBody3D

@export var player_path: NodePath
@export var nav_region_path: NodePath
@export var view_range: float = 160.0
@export var detection_range: float = 25.0
@export var agro_range: float = detection_range / 2.0
@export var investigate_range: float = 5
@export var light_detection_tolerence: float = 1.0


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var stalking_timer: Timer = $StalkingTimer
@onready var waiting_timer: Timer = $WaitingTimer
@onready var left_eye: MeshInstance3D = $LeftEye
@onready var right_eye: MeshInstance3D = $RightEye


const SPEED: float = 340.0
const STALKING_DISTANCE: float = 20.0
const RUNNING_DISTANCE: float = 500.0
const STALKING_STAGE_TARGET: int = 4

var player: CharacterBody3D = null
var nav_region: NavigationRegion3D = null
var target_pos: Vector3
var sprint_factor: float = 1.0
var stalking_stage: int = 0
# 0.061

enum states {
	roaming,
	waiting,
	stalking,
	chasing,
	running_away
}

var state: states

func set_state(new_state : states) -> void:
	state = new_state


func _ready() -> void:
	randomize()
	visible = false
	initialize_ai()
	
	$DefaultEnemyModel.visible = false


## Initilizes [member player], [member nav_region], [member ray_cast_3d.target_position.z] and sets initial [member state] to [member states.ROAMING]
func initialize_ai() -> void:
	player = get_node(player_path)
	nav_region = get_node(nav_region_path)
	
	
	update_state(states.roaming)

## Sets new state and Calls [method do_state_action]
func update_state(new_state: states) -> void:
	set_state(new_state)
	do_state_action()


func _physics_process(delta: float) -> void:
	#print(states.keys()[state], global_position)
	
	if state == states.stalking:
		_face_move_direction(player.global_position)
		update_eye_spacing()
		return
	
	var next_nav_point = _handle_movement(delta)
	_face_move_direction(next_nav_point)
	move_and_slide()

const EYE_MIN_DISTANCE := 5.0
const EYE_MAX_DISTANCE := 40.0

func update_eye_spacing() -> void:
	var distance := global_position.distance_to(player.global_position)

	var t := inverse_lerp(EYE_MIN_DISTANCE, EYE_MAX_DISTANCE, distance)
	t = clamp(t, 0.0, 1.0)

	left_eye.position.x = lerp(-0.061, -0.5, t)
	right_eye.position.x = lerp(0.061, 0.5, t)

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


## Sets target position to a random point on the map
func roam():
	set_sprint_factor()
	target_pos = get_random_nav_point()

# Sets target position to the players position
func chase():
	set_sprint_factor(2.5)
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
		states.chasing:
			chase()
		states.waiting:
			print("IM WAITING")
			wait()
		states.running_away:
			run_away()

func run_away():
	set_sprint_factor(2.5)
	var potential_position = get_random_nav_point((-player.global_basis.z * (RUNNING_DISTANCE)) + player.global_position, 1)
	potential_position.y = 0
	target_pos = potential_position

func wait() -> void:
	if waiting_timer.is_stopped():
		waiting_timer.start()

func _initiate_stalking() -> void:
	stalking_stage = 1
	stalk()

func stalk() -> void:
	var potential_position = Vector3.ZERO
	for i in range(100):
		potential_position = get_random_nav_point((player.global_basis.z * (STALKING_DISTANCE/stalking_stage)) + player.global_position, min(3+i,10))
		if potential_position.distance_to(player.global_position) > STALKING_DISTANCE/stalking_stage:
			break
		print("im a failure")
	if potential_position.distance_to(player.global_position) < STALKING_DISTANCE/stalking_stage:
		update_state(states.waiting)
		return
	update_state(states.stalking)
	potential_position.y = 0
	position = potential_position

	visible = true
	stalking_timer.start()

func _next_stalking_stage() -> void:
	if stalking_stage == STALKING_STAGE_TARGET:
		update_state(states.chasing)
		return
	stalking_stage +=1
	stalk()

func _on_player_detection_area_body_entered(body: Node3D) -> void:
	if state == states.roaming and body == player:
		_initiate_stalking()


func _on_navigation_agent_3d_target_reached() -> void:
	if state == states.running_away:
		update_state(states.roaming)
		return
	do_state_action()

func _on_light_detection_area_area_entered(_area: Area3D) -> void:
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
	
	update_state(states.running_away)
	stalking_timer.stop()
	waiting_timer.stop()
	raycast.call_deferred("queue_free")


func _on_stalking_timer_timeout() -> void:
	_next_stalking_stage()


func _on_waiting_timer_timeout() -> void:
	_initiate_stalking()
	
func _on_jumpscare_area_body_entered(body: Node3D) -> void:
	if body != player: return
	
	left_eye.visible = false
	right_eye.visible = false
	$AnimationPlayer.play("jump_scare")
	body.is_immune = true

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "jump_scare": return
	
	get_tree().reload_current_scene()
