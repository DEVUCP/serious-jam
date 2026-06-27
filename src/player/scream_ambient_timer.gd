extends Timer

@onready var scream_ambient_sfx: SpatialAudioPlayer3D = $".."


func _on_timeout() -> void:
	randomize()
	if randi_range(1, 100) <= 15:
		scream_ambient_sfx.play()
