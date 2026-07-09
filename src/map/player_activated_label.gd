extends Node3D

const ANALOGUE_STICK_ICON = preload("res://assets/textures/left_stick_icon.png")
const WASD_ICON = preload("res://assets/textures/wasd_icon.png")
const PS4_CROSS_ICON = preload("res://assets/textures/ps4_cross_icon.png")
const PS4_CIRCLE_ICON = preload("res://assets/textures/ps4_circle_icon.png")
const PS4_R1_ICON = preload("res://assets/textures/ps4_r1_icon.png")
const PS4_L1_ICON = preload("res://assets/textures/ps4_l1_icon.png")
const L3_ICON = preload("res://assets/textures/ps4_l3_icon.png")
const XBOX_A_ICON = preload("res://assets/textures/xbox_A_icon.png")
const XBOX_B_ICON = preload("res://assets/textures/xbox_B_icon.png")
const XBOX_RB_ICON = preload("res://assets/textures/xbox_RB_icon.png")
const XBOX_LB_ICON = preload("res://assets/textures/xbox_LB_icon.png")
const E_ICON = preload("res://assets/textures/E_icon.png")
const SHIFT_ICON = preload("res://assets/textures/shift_icon.png")
const RIGHT_CLICK_ICON = preload("res://assets/textures/right_click_icon.png")
const RIGHT_STICK_ICON = preload("res://assets/textures/right_stick_icon.png")
const SPACEBAR_ICON = preload("res://assets/textures/spacebar_icon.png")
@onready var movement_icon: Sprite3D = $MovementLabel/MovementIcon
@onready var sprint_icon: Sprite3D = $SprintLabel/SprintIcon
@onready var slow_walk_icon: Sprite3D = $SlowWalkLabel/SlowWalkIcon
@onready var crank_icon: Sprite3D = $CrankLabel/CrankIcon
@onready var pickup_item_icon: Sprite3D = $PickUpItemLabel/PickupItemIcon
@onready var escape_icon: Sprite3D = $EscapeLabel/EscapeIcon
@onready var wind_up_icon: Sprite3D = $WindUpLabel/WindUpIcon



var tutorial_texts = {
	"movement" : "for Movement"
}

var controller_type

var keybinds = {
	"movement": {
		"PS4" : ANALOGUE_STICK_ICON,
		"XBOX" : ANALOGUE_STICK_ICON,
		"PC" : WASD_ICON
	},
	"interact": {
		"PS4" : PS4_CIRCLE_ICON,
		"XBOX" : XBOX_B_ICON,
		"PC" : E_ICON
	},
	"sprint": {
		"PS4" : L3_ICON,
		"XBOX" : L3_ICON,
		"PC" : SHIFT_ICON
	},
	"crank": {
		"PS4" : PS4_R1_ICON,
		"XBOX" : XBOX_RB_ICON,
		"PC" : RIGHT_CLICK_ICON
	},
	"slow_walk": {
		"PS4" : PS4_L1_ICON,
		"XBOX" : XBOX_LB_ICON,
		"PC" : SPACEBAR_ICON
	}
}

func _ready() -> void:
	controller_type = "PC"
	var connected_device = Input.get_connected_joypads()
	if connected_device:
		var controller_name = Input.get_joy_name(connected_device[0])
		if controller_name.contains("PS"):
			controller_type = "PS4"
		else:
			controller_type = "XBOX"
			
	movement_icon.texture = keybinds["movement"][controller_type]
	sprint_icon.texture = keybinds["sprint"][controller_type]
	slow_walk_icon.texture = keybinds["slow_walk"][controller_type]
	pickup_item_icon.texture = keybinds["interact"][controller_type]
	crank_icon.texture = keybinds["crank"][controller_type]
	wind_up_icon.texture = pickup_item_icon.texture
	escape_icon.texture = pickup_item_icon.texture

func _on_area_3d_body_entered(body: Node3D, area: Area3D) -> void:
	var label: Label3D = area.get_parent()
	label.visible = true
	

func _on_area_3d_body_exited(body: Node3D, area: Area3D) -> void:
	area.get_parent().visible = false
