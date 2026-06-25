extends Node3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var interact_area: InteractArea = $InteractArea

var player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_interact_area_interacted_with(something: Variant) -> void:
	player = something
	player.is_immune = true
	animation_player.play("jump_scare")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	player.enable_input_capture()
	player.is_immune = false
	interact_area.monitoring = false
	interact_area.monitorable = false
