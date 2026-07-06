extends Control

const PLAY_SCENE := "res://src/map/shader_main_scene.tscn"

var play_scene: PackedScene
var loading := false

@onready var main_menu_page: Control = $MainMenuPage
@onready var settings_page: Control = $SettingsPage
@onready var master_slider: HSlider = $SettingsPage/Panel/VBoxContainer/HBoxContainer/MarginContainer/MasterSlider
@onready var ambience_slider: HSlider = $SettingsPage/Panel/VBoxContainer/HBoxContainer2/MarginContainer/AmbienceSlider
@onready var sfx_slider: HSlider = $SettingsPage/Panel/VBoxContainer/HBoxContainer3/MarginContainer/SFXSlider
@onready var loading_page: Control = $LoadingPage
@onready var sensitivity_slider: HSlider = $SettingsPage/Panel/VBoxContainer/HBoxContainer4/MarginContainer/SensitivitySlider
@onready var hover_audio_player: AudioStreamPlayer = $HoverAudioPlayer
@onready var toggle_audio_player: AudioStreamPlayer = $ToggleAudioPlayer
@onready var old_grabber_area = master_slider.get_theme_stylebox("grabber_area")
@onready var old_grabber = master_slider.get_theme_icon("grabber")

func _ready() -> void:
	sensitivity_slider.value = Settings.mouse_sens * 20.0


func _go_to_loading(loaded_scene_path : String) -> void:
	var loading_screen = preload("res://src/loading_screen.tscn").instantiate()
	loading_screen.scene_path_to_load = loaded_scene_path
	get_tree().root.add_child(loading_screen)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = loading_screen

func _on_settings_button_pressed() -> void:
	var mainmenutween = create_tween()
	mainmenutween.set_ease(Tween.EASE_OUT)
	mainmenutween.set_trans(Tween.TRANS_EXPO)
	mainmenutween.tween_property(
		$MainMenuPage,
		"offset_transform_position:x",
		-1300,
		0.5
	)
	mainmenutween.tween_property(
		$MainMenuPage,
		"visible",
		false,
		0.1
	)
	$SettingsPage.offset_transform_position.x = 1300
	$SettingsPage.visible = true
	var settingstween = create_tween()
	settingstween.set_ease(Tween.EASE_OUT)
	settingstween.set_trans(Tween.TRANS_EXPO)
	settingstween.tween_property(
		$SettingsPage,
		"offset_transform_position:x",
		0,
		0.5
	)

func _on_tutorial_button_pressed() -> void:
	var tutorial_scene_path = "res://src/tutorial_shader.tscn"
	_go_to_loading(tutorial_scene_path)


func _on_play_button_pressed() -> void:
	loading_page.visible = true
	main_menu_page.visible = false
	settings_page.visible = false
	#if play_scene:
	_go_to_loading(PLAY_SCENE)
	#else:
		#print("Play scene is still loading...")


func _on_quit_button_pressed() -> void:
	if OS.has_feature("web"):
		return
	get_tree().quit()

func _on_settings_back_button_pressed() -> void:
	var settingstween = create_tween()
	settingstween.set_ease(Tween.EASE_OUT)
	settingstween.set_trans(Tween.TRANS_EXPO)
	settingstween.tween_property(
		$SettingsPage,
		"offset_transform_position:x",
		1300,
		0.5
	)
	settingstween.tween_property(
		$SettingsPage,
		"visible",
		false,
		0.1
	)
	$MainMenuPage.offset_transform_position.x = -1300
	$MainMenuPage.visible = true
	var mainmenutween = create_tween()
	mainmenutween.set_ease(Tween.EASE_OUT)
	mainmenutween.set_trans(Tween.TRANS_EXPO)
	mainmenutween.tween_property(
		$MainMenuPage,
		"offset_transform_position:x",
		0,
		0.5
	)
	

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx_slider.value / 20.0))


func _on_ambience_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(ambience_slider.value / 20.0))


func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_slider.value / 20.0))


func _on_sensitivity_slider_value_changed(value: float) -> void:
	Settings.mouse_sens = value / 20.0


func _on_check_button_toggled(toggled_on: bool) -> void:
	toggle_audio_player.play()
	Settings.toggle_sprint_setting = toggled_on


func _on_button_focus_entered() -> void:
	hover_audio_player.play()

func _on_button_mouse_exited(button) -> void:
	button.offset_transform_scale = Vector2(1, 1)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(
		button,
		"offset_transform_rotation",
		deg_to_rad(0),
		0.4
	)
	var sizetween = create_tween()
	sizetween.set_ease(Tween.EASE_OUT)
	sizetween.set_trans(Tween.TRANS_SINE)
	sizetween.tween_property(
		button,
		"offset_transform_scale",
		Vector2(1,1),
		0.4
	)


func _on_button_mouse_entered(button) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(
		button,
		"offset_transform_rotation",
		deg_to_rad(-2),
		0.4
	)
	var sizetween = create_tween()
	sizetween.set_ease(Tween.EASE_OUT)
	sizetween.set_trans(Tween.TRANS_EXPO)
	sizetween.tween_property(
		button,
		"offset_transform_scale",
		Vector2(1.16,1.16),
		0.4
	)

func _on_settings_element_mouse_entered(element) -> void:
	var hbox: HBoxContainer

	if element is Label:
		hbox = element.get_parent().get_parent()
	elif element is MarginContainer:
		hbox = element.get_parent()
	else: # HSlider / CheckBox
		hbox = element.get_parent().get_parent()

	var label: Label = hbox.get_child(0).get_child(0)
	var control: Control = hbox.get_child(1).get_child(0)

	label.modulate = Color("A15FBD")

	if control is CheckButton:
		control.modulate = Color("A15FBD")
	elif control is HSlider and element is not HSlider:
		control.add_theme_stylebox_override(
			"grabber_area",
			control.get_theme_stylebox("grabber_area_highlight")
		)

		control.add_theme_icon_override(
			"grabber",
			control.get_theme_icon("grabber_highlight")
		)

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(hbox, "offset_transform_scale", Vector2(1, 1.16), 0.4)


func _on_settings_element_mouse_exited(element) -> void:
	var hbox: HBoxContainer

	if element is Label:
		hbox = element.get_parent().get_parent()
	elif element is MarginContainer:
		hbox = element.get_parent()
	else: # HSlider / CheckBox
		hbox = element.get_parent().get_parent()

	var label: Label = hbox.get_child(0).get_child(0)
	var control: Control = hbox.get_child(1).get_child(0)

	if control is CheckButton:
		control.modulate = Color.WHITE
	elif control is HSlider and element is not HSlider:
		control.add_theme_stylebox_override("grabber_area", old_grabber_area)
		control.add_theme_icon_override("grabber", old_grabber)

	label.modulate = Color.WHITE
	hbox.modulate = Color.WHITE

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(hbox, "offset_transform_scale", Vector2.ONE, 0.4)
