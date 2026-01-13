extends CanvasLayer
class_name ChatUI

@export var max_message_length: int = 180
@export var max_history: int = 100

@onready var chat_log: RichTextLabel = $Root/Panel/VBox/Scroll/ChatLog
@onready var chat_input: LineEdit = $Root/Panel/VBox/ChatInput
@onready var scroll: ScrollContainer = $Root/Panel/VBox/Scroll

signal message_submitted(text: String)

var _history: Array[Dictionary] = []

func _ready() -> void:
	chat_log.text = "[b]UI test[/b]\n"
	chat_log.bbcode_enabled = true
	chat_log.fit_content = true

	chat_input.text_submitted.connect(_on_text_submitted)
	_append_system("Chat connected")

func _on_text_submitted(text: String) -> void:
	var t := text.strip_edges()
	if t == "":
		return

	# hard limit length
	if t.length() > max_message_length:
		t = t.substr(0, max_message_length)

	message_submitted.emit(t)
	chat_input.clear()

func add_message(msg: Dictionary) -> void:
	# msg expected: { "name": String, "text": String, "time": String, "player_id": int }
	_history.append(msg)
	if _history.size() > max_history:
		_history.pop_front()

	_render()

func set_history(messages: Array) -> void:
	_history.clear()
	for m in messages:
		_history.append(m)
	while _history.size() > max_history:
		_history.pop_front()
	_render()

func _append_system(text: String) -> void:
	print("RENDER history size=", _history.size())
	add_message({"name":"SYSTEM", "text": text, "time": Time.get_time_string_from_system(), "player_id": 0})

func _render() -> void:
	# Detect whether user is already at bottom; only autoscroll if they are.
	var should_autoscroll := _is_near_bottom()

	var lines: Array[String] = []
	for m in _history:
		var time := _safe_bb(str(m.get("time", "")))
		var name := _safe_bb(str(m.get("name", "Player")))
		var text := _safe_bb(str(m.get("text", "")))

		lines.append("[color=yellow][%s][/color] [b]%s:[/b] %s" % [time, name, text])

	chat_log.text = "\n".join(lines)

	if should_autoscroll:
		await get_tree().process_frame
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _is_near_bottom() -> bool:
	var bar := scroll.get_v_scroll_bar()
	return bar.value >= (bar.max_value - 20)

func _safe_bb(s: String) -> String:
	# Prevent users breaking BBCode formatting
	return s.replace("[", "\\[").replace("]", "\\]")
