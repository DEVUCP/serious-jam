extends CharacterBody3D

@export var player_path: NodePath
@export var nav_region_path: NodePath
@export var view_range: float = 160.0
@export var detection_range: float = 25.0
@export var agro_range: float = detection_range / 2.0
@export var investigate_range: float = 5

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var investigating_cooldown: Timer = $InvestigatingCooldown

const SPEED: float = 3.0

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
	print(state)
	
	velocity = Vector3.ZERO
	
	#ray_cast_3d.set_target_position(to_local(player.global_position))
	
	_looking()
	
	if _is_player_detected():
		_on_player_detected()
		
	
	navigation_agent_3d.set_target_position(target_pos)
	var next_nav_point = navigation_agent_3d.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * SPEED * sprint_factor
	look_at(next_nav_point)
	
	move_and_slide()

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
	target_pos = get_random_nav_point()
	
func investigate():
	if investigation_positions.size() == 0: 
		state = states.roaming
		check_state()
		return
	
	if investigating_cooldown.is_stopped():
		target_pos = investigation_positions.pop_front()
		investigating_cooldown.start()
		
		print("INVESTIGATING AT ", target_pos)
	
func chase():
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
