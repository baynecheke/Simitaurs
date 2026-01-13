extends Node
const HOST: String = "godot-multiplayer-fireba-89f3e-default-rtdb.firebaseio.com"
const host_url = "https://" + HOST
func _get_player_url(player_id) -> String:
	var path_player = "/players/%s.json" % player_id
	return host_url + path_player

func _get_all_players_url() -> String:
	return "/players.json"
func _get_chat_messages_url() -> String:
	# FULL URL for HTTPRequest (GET/POST)
	return host_url + "/chat/messages.json"

func _get_chat_messages_stream_path() -> String:
	# PATH for SSE stream request line
	return "/chat/messages.json"
