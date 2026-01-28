extends Node
class_name ChatStream
var _buffer: String = ""
var _listening: bool = false
var _reconnect_delay: float = 1.0
const EVENT_TYPE_PREFIX := "event: "
const EVENT_DATA_PREFIX := "data: "
const RECONNECT_DELAY_MAX := 15.0

signal message_received(msg: Dictionary)

func start() -> void:
	if _listening:
		return
	_listening = true
	_start_listening()

func _start_listening() -> void:
	await _listen_loop()

func _listen_loop() -> void:
	while true:
		var ok := await _listen_once()
		if not ok:
			await get_tree().create_timer(_reconnect_delay).timeout
			_reconnect_delay = min(_reconnect_delay * 2.0, RECONNECT_DELAY_MAX)
		else:
			_reconnect_delay = 1.0
func _listen_once() -> bool:
	var tcp := await _setup_tcp_stream()
	if tcp == null:
		return false

	var tls := await _setup_tls_stream(tcp)
	if tls == null:
		return false

	_start_sse_stream(tls)

	while true:
		var response := await _read_stream_response(tls)
		if response == "":
			return false

		var events := _parse_response_event_data(response)
		for e in events:
			_emit_messages_from_put(e)

	# Should never reach, but keeps the compiler happy
	return false


func _setup_tcp_stream() -> StreamPeerTCP:
	var tcp := StreamPeerTCP.new()
	var err := tcp.connect_to_host(FirebaseUrls.HOST, 443)
	if err != OK:
		push_error("ChatStream: TCP connect failed: %s" % err)
		return null

	while tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		await get_tree().process_frame
		tcp.poll()

	return tcp

func _setup_tls_stream(tcp: StreamPeerTCP) -> StreamPeerTLS:
	var tls := StreamPeerTLS.new()
	var err := tls.connect_to_stream(tcp, FirebaseUrls.HOST)
	if err != OK:
		push_error("ChatStream: TLS connect failed: %s" % err)
		return null

	while tls.get_status() != StreamPeerTLS.STATUS_CONNECTED:
		await get_tree().process_frame
		tls.poll()

	return tls

func _start_sse_stream(stream: StreamPeer) -> void:
	var path: String = FirebaseUrls._get_chat_messages_stream_path()
	var request_line := "GET %s HTTP/1.1" % path
	var headers := [
		"Host: %s" % FirebaseUrls.HOST,
		"Accept: text/event-stream",
		"Connection: keep-alive",
	]
	var req := request_line + "\n" + "\n".join(headers) + "\n\n"
	stream.put_data(req.to_ascii_buffer())

func _read_stream_response(stream: StreamPeer) -> String:
	stream.poll()
	if stream is StreamPeerTLS:
		var tls := stream as StreamPeerTLS
		if tls.get_status() != StreamPeerTLS.STATUS_CONNECTED:
			return ""
	var avail := stream.get_available_bytes()
	while avail == 0:
		await get_tree().process_frame
		stream.poll()
		if stream is StreamPeerTLS:
			var tls := stream as StreamPeerTLS
			if tls.get_status() != StreamPeerTLS.STATUS_CONNECTED:
				return ""
		avail = stream.get_available_bytes()

	return stream.get_string(avail)

class EventData:
	var type: String
	var data: Dictionary

func _parse_event_data(event_str: String) -> EventData:
	var lines := event_str.split("\n")
	# We accept events that may have extra lines; find the first "event:" and "data:"
	var et := ""
	var ds_lines: Array[String] = []
	for l in lines:
		if l.begins_with(EVENT_TYPE_PREFIX):
			et = l.substr(EVENT_TYPE_PREFIX.length())
		elif l.begins_with(EVENT_DATA_PREFIX):
			ds_lines.append(l.substr(EVENT_DATA_PREFIX.length()))

	if et == "" or ds_lines.is_empty():
		return null

	var ds := "\n".join(ds_lines)
	var json: Dictionary = {}
	var parsed: Variant = JSON.parse_string(ds)
	if typeof(parsed) == TYPE_DICTIONARY:
		json = parsed

	var ev := EventData.new()
	ev.type = et
	ev.data = json
	return ev

func _parse_response_event_data(response: String) -> Array[Dictionary]:
	_buffer += response
	_buffer = _buffer.replace("\r", "")
	var parts := _buffer.split("\n\n")  # this is PackedStringArray

	if not _buffer.ends_with("\n\n"):
		var last_index := parts.size() - 1
		_buffer = parts[last_index]
		parts.remove_at(last_index)
	else:
		_buffer = ""

	var out: Array[Dictionary] = []
	for p in parts:
		var ev := _parse_event_data(p)
		if ev == null:
			continue
		if ev.type != "put":
			continue
		out.append(ev.data)
	return out
	

func _emit_messages_from_put(event: Dictionary) -> void:
	# Firebase event looks like: { "path": "...", "data": <dict or null> }
	if not event.has("data"):
		return
	var data = event["data"]
	if data == null:
		return

	# When path == "/", data is dict of many messages.
	# When path == "/-PushId", data is one message dict.
	if typeof(data) == TYPE_DICTIONARY:
		# Heuristic: single message has "text"
		if data.has("text") and data.has("name"):
			message_received.emit(data)
		else:
			for k in data.keys():
				var m = data[k]
				if typeof(m) == TYPE_DICTIONARY and m.has("text") and m.has("name"):
					message_received.emit(m)
