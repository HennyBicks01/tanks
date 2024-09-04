extends Control

signal host_game
signal join_game(code)

@onready var host_button = $VBoxContainer/HostButton
@onready var join_button = $VBoxContainer/JoinButton
@onready var code_input = $VBoxContainer/CodeInput
@onready var title_letters = $VBoxContainer/Title.get_children()

var time = 0
var wave_speed = 2
var wave_height = 10

func _ready():
	host_button.connect("pressed", _on_host_button_pressed)
	join_button.connect("pressed", _on_join_button_pressed)

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
