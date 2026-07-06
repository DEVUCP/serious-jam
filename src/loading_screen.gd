extends Control

@onready var tip_label: Label = $TipLabel

@export_file_path() var scene_path_to_load: String
var loaded_scene: PackedScene
var loading := false

func _init(load_scene = scene_path_to_load) -> void:
	scene_path_to_load = load_scene

func _ready() -> void:
	set_random_tip()
	ResourceLoader.load_threaded_request(scene_path_to_load)
	loading = true

const TIPS = {
	"seeing_enemy" : "the \"Hear No Evil\" monkey can't see well in the dark\n make sure to not flash him or he will see you!", 
	"hearing_enemy" : "the \"See No Evil\" monkey can't see at all\n he will hear your footsteps or flashlight, be quiet around him!",
	"stalking_enemy" : "the \"Speak No Evil\" monkey stalks and wont make noise\n you will hear a twig break before he attacks, flash him as soon as that happens!", 
	"seeing_enemy2" : "the \"See No Evil\" monkey can be noticed by its LOW pitched grunting and growling!", 
	"hearing_enemy2" : "the \"See No Evil\" monkey can be noticed by its HIGH pitched grunting and growling!",
	"stalking_enemy2" : "the \"Speak No Evil\" monkey can be noticed by its white glowing eyes and likes to hang around behind you",
	"fun_fact" : "fun fact, this game was only made in 7 days!",
	"fun_fact2" : "fun fact, at the chair circle you will find a plushie, his name is 'peeter',\nsay hi to peeter by pressing F on him"
}

func _process(_delta: float) -> void:
	if !loading:
		return

	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(scene_path_to_load, progress)

	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			#await get_tree().create_timer(3).timeout
			loaded_scene = ResourceLoader.load_threaded_get(scene_path_to_load)
			loading = false
			get_tree().change_scene_to_packed(loaded_scene)

		ResourceLoader.THREAD_LOAD_FAILED:
			loading = false
			push_error("Failed to load main menu.")


func set_random_tip() -> void:
	var random_key = TIPS.keys()[randi() % TIPS.size()]
	var random_tip = TIPS[random_key]
	tip_label.text = "tip: " + random_tip
