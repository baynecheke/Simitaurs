extends HTTPRequest
class_name ChatSender

@export var player_local: PlayerLocal
@export var player_display_name: String = ""

signal history_received(messages: Array)

func fetch_last_100() -> void:
	var url: String = FirebaseUrls._get_chat_messages_url()
	url += "?orderBy=%22%24key%22&limitToLast=100"

	print("FETCH url=", url)

	request_completed.connect(_on_history_completed, CONNECT_ONE_SHOT)
	request(url, ["Accept: application/json"], HTTPClient.METHOD_GET, "")

func send_message(text: String) -> void:
	if player_local == null:
		push_error("ChatSender: player_local not assigned.")
		return

	var name: String = player_display_name.strip_edges()
	if name == "":
		name = "Player" + str(player_local.player_id)

	var msg: Dictionary = {
		"player_id": player_local.player_id,
		"name": name,
		"text": text,
		"time": Time.get_time_string_from_system(),
		"ts": Time.get_unix_time_from_system()
	}

	var body: String = JSON.stringify(msg)
	var url: String = FirebaseUrls._get_chat_messages_url()

	request_completed.connect(_on_send_completed, CONNECT_ONE_SHOT)
	request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_send_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != RESULT_SUCCESS or code < 200 or code >= 300:
		printerr("ChatSender send failed result=%s code=%s body=%s" % [result, code, body.get_string_from_utf8()])
	print("SEND completed code=", code, "body=", body.get_string_from_utf8())

func _on_history_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != RESULT_SUCCESS or code < 200 or code >= 300:
		printerr("ChatSender history failed result=%s code=%s body=%s" % [result, code, body.get_string_from_utf8()])
		history_received.emit([])
		return

	var txt: String = body.get_string_from_utf8()

	var parsed: Variant = JSON.parse_string(txt)

	var msgs: Array = []
	if typeof(parsed) == TYPE_DICTIONARY:
		var dict := parsed as Dictionary
		for k in dict.keys():
			var m: Variant = dict[k]
			if typeof(m) == TYPE_DICTIONARY:
				msgs.append(m)

	# Sort by timestamp if present
	msgs.sort_custom(func(a, b):
		return int((a as Dictionary).get("ts", 0)) < int((b as Dictionary).get("ts", 0))
	)

	history_received.emit(msgs)
	print("HISTORY completed code=", code, " body=", body.get_string_from_utf8())
