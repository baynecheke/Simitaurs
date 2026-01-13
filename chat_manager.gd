extends Node
class_name ChatManager

@export var chat_ui: ChatUI
@export var sender: ChatSender
@export var stream: ChatStream

func _ready() -> void:
	if chat_ui == null or sender == null or stream == null:
		push_error("ChatManager: assign chat_ui, sender, stream in Inspector.")
		return

	chat_ui.message_submitted.connect(_on_message_submitted)
	sender.history_received.connect(_on_history_received)
	stream.message_received.connect(_on_message_received)

	# load last 100 first
	sender.fetch_last_100()
	print("fetch_last_100 called")
	# start realtime stream
	stream.start()
	print("stream.start called")

func _on_message_submitted(text: String) -> void:
	# Extra length safety (UI already trims, but keep it safe)
	if text.length() > chat_ui.max_message_length:
		text = text.substr(0, chat_ui.max_message_length)
	sender.send_message(text)

func _on_history_received(messages: Array) -> void:
	chat_ui.set_history(messages)

func _on_message_received(msg: Dictionary) -> void:
	chat_ui.add_message(msg)
