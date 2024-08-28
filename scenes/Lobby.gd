extends Control

@onready var chat_display = $VBoxContainer/ChatContainer/ChatDisplay
@onready var chat_input = $VBoxContainer/ChatContainer/ChatInput
@onready var start_button = $VBoxContainer/StartButton
@onready var host_code_label = $VBoxContainer/HostCodeLabel

func _ready():
	chat_input.connect("text_submitted", _on_chat_input_submitted)
	start_button.connect("pressed", _on_start_button_pressed)

func set_host_code(code):
	host_code_label.text = "Host Code: " + code

func show_start_button(show):
	start_button.visible = show

func _on_chat_input_submitted(text):
	rpc("add_chat_message", multiplayer.get_unique_id(), text)
	chat_input.clear()

@rpc("any_peer", "call_local")
func add_chat_message(sender_id, message):
	chat_display.text += "\nPlayer " + str(sender_id) + ": " + message

func _on_start_button_pressed():
	get_parent().get_parent().rpc("start_game")
