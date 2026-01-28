
extends Node
class_name FirebaseUrls

const HOST: String = "godot-multiplayer-fireba-89f3e-default-rtdb.firebaseio.com"
const host_url: String = "https://" + HOST

# --------------------
# Players
# --------------------
static func _get_player_url(player_id: int) -> String:
	return host_url + ("/players/%s.json" % str(player_id))

static func _get_all_players_url() -> String:
	return host_url + "/players.json"

# --------------------
# Chat
# --------------------
static func _get_chat_messages_url() -> String:
	return host_url + "/chat/messages.json"

static func _get_chat_messages_stream_path() -> String:
	return "/chat/messages.json"

# --------------------
# Combat (NEW)
# --------------------
static func _get_combat_inbox_url(target_player_id: int) -> String:
	# where requests for THIS player go
	return host_url + ("/combat/requests/%s.json" % str(target_player_id))

static func _get_combat_request_url(target_player_id: int, request_key: String) -> String:
	return host_url + ("/combat/requests/%s/%s.json" % [str(target_player_id), request_key])

static func _get_battles_url() -> String:
	return host_url + "/combat/battles.json"

static func _get_battle_url(battle_id: String) -> String:
	return host_url + ("/combat/battles/%s.json" % battle_id)
