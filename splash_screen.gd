extends Control

const MAIN_MENU_SCENE := "res://src/main_menu.tscn"

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	var loading_screen = preload("res://src/loading_screen.tscn").instantiate()
	loading_screen.scene_path_to_load = MAIN_MENU_SCENE
	get_tree().root.add_child(loading_screen)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = loading_screen
