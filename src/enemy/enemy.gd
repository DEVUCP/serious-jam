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

const SPEED: float = 3.0

var dirt_sfx = preload("res://assets/sounds/dirt_footsteps.mp3")
var dirt_sprinting_sfx = preload("res://assets/sounds/dirt_footsteps_run.mp3")

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

func _ready() -> void:
	randomize()
	
	player = get_node(player_path)
	nav_region = get_node(nav_region_path)
	
	ray_cast_3d.target_position.z = -detection_range
	
	state = states.roaming
	
	roam()

func _physics_process(delta: float) -> void:
	#print(states.keys()[state])
	
	velocity = Vector3.ZERO
	
	#ray_cast_3d.set_target_position(to_local(player.global_position))
	
	_looking()
	_update_detection_range()
	
	if _is_player_detected():
		_on_player_detected()
		
	if target_pos == Vector3.ZERO: 
		check_state()
		return
	
	var map_rid: RID = get_world_3d().get_navigation_map()
	var closest_point = NavigationServer3D.map_get_closest_point(map_rid, target_pos)
	navigation_agent_3d.set_target_position(closest_point)
	
	var next_nav_point = navigation_agent_3d.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * SPEED * sprint_factor
	
	var direction: Vector3 = global_position.direction_to(next_nav_point)
	var target_basis: Basis = Basis.looking_at(direction, Vector3.UP)
	
	basis = basis.slerp(target_basis, 0.1)
	if velocity and !footstep_sfx.playing:
		footstep_sfx.play()
	move_and_slide()

func _update_detection_range() -> void:
	var light_detection_factor = player.get_light_detection_factor()
	
	detection_range = 8.0 + (15 * light_detection_factor)
	agro_range = detection_range / 2.0
	
	ray_cast_3d.target_position.z = -detection_range

func _is_in_agro_range() -> bool:
	return global_position.distance_to(player.global_position) < agro_range

func _on_player_detected() -> void:
	if _is_in_agro_range():
		state = states.chasing
	else:
		state = states.investigating
		if !investigating_cooldown.is_stopped(): return
		
		investigation_positions.clear()
		var last_known_player_location = player.global_position
		for i in range(3):
			randomize()
			investigation_positions.append(last_known_player_location + Vector3(randf_range(-investigate_range, investigate_range), 0, randf_range(-investigate_range, investigate_range)))
		
	check_state()

func _is_player_detected() -> bool:
	return ray_cast_3d.is_colliding() && ray_cast_3d.get_collider() == player

func _looking() -> void:
	var to_player = (player.global_transform.origin - global_transform.origin).normalized()
	var forward = -global_transform.basis.z
	var angle_deg = rad_to_deg(acos(clamp(forward.dot(to_player), -1.0, 1.0)))
	if angle_deg > view_range * 0.5:
		return
	
	var target = player.global_position + Vector3.UP * 0.5
	ray_cast_3d.look_at(target, Vector3.UP)

func roam():
	if footstep_sfx.stream != dirt_sfx:
		footstep_sfx.stream = dirt_sfx
	target_pos = get_random_nav_point()
	
func investigate():
	if footstep_sfx.stream != dirt_sfx:
		footstep_sfx.stream = dirt_sfx
	if investigation_positions.size() == 0: 
		state = states.roaming
		check_state()
		return
	
	if investigating_cooldown.is_stopped():
		target_pos = investigation_positions.pop_front()
		$MeshInstance3D3.global_position = target_pos

		investigating_cooldown.start()
		
		print("INVESTIGATING AT ", target_pos)
	else:
		target_pos = Vector3.ZERO
	
func chase():
	if footstep_sfx.stream != dirt_sprinting_sfx:
		footstep_sfx.stream = dirt_sprinting_sfx
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

func check_state():
	match state:
		states.roaming:
			sprint_factor = 1
			roam()
		states.investigating:
			sprint_factor = 1
			investigate()
		states.chasing:
			sprint_factor = 1.5
			chase()

func _on_navigation_agent_3d_target_reached() -> void:
	check_state()

func _on_light_detection_area_area_entered(area: Area3D) -> void:
	if player.get_flashlight().get_light_level() < light_detection_tolerence: return
	
	var raycast: RayCast3D = RayCast3D.new()
	add_child(raycast)
	raycast.set_collision_mask_value(1, false)
	raycast.set_collision_mask_value(3, true)
	raycast.target_position = to_local(player.global_position)
	
	if raycast.is_colliding():
		raycast.call_deferred("queue_free")
		return
	
	state = states.chasing
	check_state()
	
	raycast.call_deferred("queue_free")
