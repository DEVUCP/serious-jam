extends Control

var sound_level = 0
@onready var speaker_0: TextureRect = $speaker0
@onready var speaker_1: TextureRect = $speaker1
@onready var speaker_2: TextureRect = $speaker2
@onready var speaker_3: TextureRect = $speaker3
@onready var speakers = [speaker_0, speaker_1, speaker_2, speaker_3]

func set_sound_level(new_val : float) -> void:
	sound_level = new_val

func _process(delta: float) -> void:
	_update_sound_indicator()


func _update_sound_indicator() -> void:
	#print(sound_level)
	if sound_level < 3:
		_set_speaker_visibility(0)
	elif sound_level < 11:
		_set_speaker_visibility(1)
	elif sound_level < 41:
		_set_speaker_visibility(2)
	else:
		_set_speaker_visibility(3)

func _set_speaker_visibility(indx: int) -> void:
	for speaker in speakers:
		speaker.visible = false
	speakers[indx].visible = true
