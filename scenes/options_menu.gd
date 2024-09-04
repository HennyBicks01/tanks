extends Control

signal back_to_main_menu

@onready var sound_volume_slider = $CenterContainer/VBoxContainer/SoundVolumeContainer/SoundVolumeSlider
@onready var music_volume_slider = $CenterContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
@onready var screen_shake_checkbox = $CenterContainer/VBoxContainer/ScreenShakeContainer/ScreenShakeCheckBox
@onready var back_button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	back_button.connect("pressed", _on_back_button_pressed)
	sound_volume_slider.connect("value_changed", _on_sound_volume_changed)
	music_volume_slider.connect("value_changed", _on_music_volume_changed)
	screen_shake_checkbox.connect("toggled", _on_screen_shake_toggled)
	
	# Load saved settings
	load_settings()

func _on_back_button_pressed():
	save_settings()
	emit_signal("back_to_main_menu")

func _on_sound_volume_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func _on_music_volume_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_screen_shake_toggled(enabled):
	# You'll need to implement screen shake functionality in your game
	# For now, we'll just print the state
	print("Screen shake ", "enabled" if enabled else "disabled")

func save_settings():
	var settings = {
		"sound_volume": sound_volume_slider.value,
		"music_volume": music_volume_slider.value,
		"screen_shake": screen_shake_checkbox.button_pressed
	}
	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	file.store_var(settings)
	file.close()

func load_settings():
	if FileAccess.file_exists("user://settings.save"):
		var file = FileAccess.open("user://settings.save", FileAccess.READ)
		var settings = file.get_var()
		file.close()
		
		sound_volume_slider.value = settings.get("sound_volume", 1.0)
		music_volume_slider.value = settings.get("music_volume", 1.0)
		screen_shake_checkbox.button_pressed = settings.get("screen_shake", true)
		
		# Apply loaded settings
		_on_sound_volume_changed(sound_volume_slider.value)
		_on_music_volume_changed(music_volume_slider.value)
		_on_screen_shake_toggled(screen_shake_checkbox.button_pressed)
