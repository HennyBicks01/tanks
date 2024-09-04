extends Control

signal start_single_player
signal show_multiplayer_menu
signal show_options

@onready var single_player_button = $CenterContainer/VBoxContainer/ButtonsContainer/SinglePlayerButton
@onready var multiplayer_button = $CenterContainer/VBoxContainer/ButtonsContainer/MultiplayerButton
@onready var options_button = $CenterContainer/VBoxContainer/ButtonsContainer/OptionsButton
@onready var title_letters = $CenterContainer/VBoxContainer/Title.get_children()

var time = 0
var wave_speed = 2
var wave_height = 10

func _ready():
	single_player_button.connect("pressed", _on_single_player_button_pressed)
	multiplayer_button.connect("pressed", _on_multiplayer_button_pressed)
	options_button.connect("pressed", _on_options_button_pressed)

func _process(delta):
	time += delta
	for i in range(title_letters.size()):
		var offset = sin(time * wave_speed + i * 0.5) * wave_height
		title_letters[i].position.y = offset

func _on_single_player_button_pressed():
	emit_signal("start_single_player")

func _on_multiplayer_button_pressed():
	emit_signal("show_multiplayer_menu")

func _on_options_button_pressed():
	emit_signal("show_options")
