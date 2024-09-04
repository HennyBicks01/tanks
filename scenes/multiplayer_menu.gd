extends Control

signal host_game
signal join_game(code)
signal back_to_main_menu

@onready var host_button = $CenterContainer/VBoxContainer/HostButton
@onready var join_button = $CenterContainer/VBoxContainer/JoinButton
@onready var code_input = $CenterContainer/VBoxContainer/CodeInput
@onready var back_button = $CenterContainer/VBoxContainer/BackButton
@onready var title_letters = $CenterContainer/VBoxContainer/Title.get_children()

var time = 0
var wave_speed = 2
var wave_height = 5

func _ready():
	host_button.connect("pressed", _on_host_button_pressed)
	join_button.connect("pressed", _on_join_button_pressed)
	back_button.connect("pressed", _on_back_button_pressed)

func _process(delta):
	time += delta
	for i in range(title_letters.size()):
		var offset = sin(time * wave_speed + i * 0.5) * wave_height
		title_letters[i].position.y = offset

func _on_host_button_pressed():
	emit_signal("host_game")

func _on_join_button_pressed():
	var code = code_input.text
	if code.length() > 0:
		emit_signal("join_game", code)

func _on_back_button_pressed():
	emit_signal("back_to_main_menu")
