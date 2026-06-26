extends Control

@onready var main_menu_page: Control = $MainMenuPage
@onready var settings_page: Control = $SettingsPage
@onready var master_slider: HSlider = $SettingsPage/Panel/VBoxContainer/HBoxContainer/MarginContainer/MasterSlider
@onready var ambience_slider: HSlider = $SettingsPage/Panel/VBoxContainer/HBoxContainer2/MarginContainer/AmbienceSlider
@onready var sfx_slider: HSlider = $SettingsPage/Panel/VBoxContainer/HBoxContainer3/MarginContainer/SFXSlider


func _on_settings_button_pressed() -> void:
	main_menu_page.visible = false
	settings_page.visible = true

func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/tutorial_shader.tscn")


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://src/map/shader_main_scene.tscn")
	


func _on_quit_button_pressed() -> void:
	if OS.has_feature("web"):
		return
	get_tree().quit()

func _on_settings_back_button_pressed() -> void:
	main_menu_page.visible = true
	settings_page.visible = false
	

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx_slider.value / 20.0))


func _on_ambience_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(ambience_slider.value / 20.0))


func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_slider.value / 20.0))
