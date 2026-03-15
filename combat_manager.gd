extends Node
class_name CombatManager
var inbox_requester: HTTPRequest # New!
var inbox_timer: Timer
# 1. Assign these in the Inspector!
@export var player_local: PlayerLocal
@export var combat_ui: CombatUI
var combat_requester: HTTPRequest
var current_target_id: int = -1
var in_combat: bool = false
var accept_requester: HTTPRequest
func _ready() -> void:
	# Safety check to ensure you wired the Inspector variables
	if player_local == null or combat_ui == null:
		push_error("CombatManager: Please assign 'Player Local' and 'Combat UI' in the Inspector.")
		return

	# 2. Find the CombatArea on your local player
	var combat_area = player_local.get_node_or_null("CombatArea")
	if combat_area == null:
		push_error("CombatManager: PlayerLocal needs a child node named 'CombatArea'.")
		return

	# 3. Listen for proximity signals
	combat_area.touching_player.connect(_on_touching_player)
	combat_area.stopped_touching_player.connect(_on_stopped_touching_player)

	# 4. Listen for UI buttons (we will fill these functions in Phase 2)
	combat_ui.request_pressed.connect(_on_request_pressed)
	combat_ui.accept_pressed.connect(_on_accept_pressed)
	combat_ui.decline_pressed.connect(_on_decline_pressed)
	inbox_requester = HTTPRequest.new()
	add_child(inbox_requester)
	inbox_requester.request_completed.connect(_on_inbox_checked)

	inbox_timer = Timer.new()
	inbox_timer.wait_time = 1.5 # Check Firebase every 1.5 seconds
	inbox_timer.autostart = true
	inbox_timer.timeout.connect(_check_inbox)
	add_child(inbox_timer)
	

	# 5. Initialize UI state
	combat_ui.call_deferred("set_request_visible", false)
	combat_ui.call_deferred("show_incoming", false)
	combat_ui.call_deferred("show_battle", false)
	combat_requester = HTTPRequest.new()
	add_child(combat_requester)
	combat_requester.request_completed.connect(_on_combat_request_completed)
	
	accept_requester = HTTPRequest.new()
	add_child(accept_requester)
	accept_requester.request_completed.connect(_on_combat_request_completed)
# --- Proximity Logic (Phase 1) ---

func _on_touching_player(other_player_id: int) -> void:
	if in_combat:
		return
		
	# Store who we are targeting
	current_target_id = other_player_id
	print("Touching player: ", current_target_id) # Debug log
	
	# Show the button
	combat_ui.set_request_visible(true)

func _on_stopped_touching_player(other_player_id: int) -> void:
	# Only hide if we walked away from the person we were targeting
	if other_player_id != current_target_id:
		return
		
	print("Stopped touching player: ", current_target_id) # Debug log
	current_target_id = -1
	combat_ui.set_request_visible(false)

# --- Button Logic (Phase 2 Placeholders) ---

func _on_request_pressed() -> void:
	if current_target_id == -1:
		return
		
	print("Sending combat request to: ", current_target_id)
	
	# 1. Prepare the data we want to send
	var request_data = {
		"sender_id": player_local.player_id,
		"status": "pending",
		"timestamp": Time.get_unix_time_from_system()
	}
	var json_data = JSON.stringify(request_data)
	
	# 2. Get the exact Firebase URL from your FirebaseUrls script
	# We use our own player_id as the 'request_key' to prevent duplicate spam
	var url = FirebaseUrls._get_combat_request_url(current_target_id, str(player_local.player_id))
	
	# 3. Send the HTTP PUT request
	var error = combat_requester.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_PUT, json_data)
	
	if error != OK:
		push_error("Failed to send combat request. Error code: ", error)
	else:
		# Hide the request button locally so we don't keep clicking it
		combat_ui.set_request_visible(false)
		print("Request sent to server successfully!")

func _on_accept_pressed() -> void:
	print("Accepting request from: ", current_target_id)
	
	# 1. Hide the incoming request UI
	combat_ui.show_incoming(false)
	
	# 2. Create a unique Battle ID (combining both player IDs makes it unique)
	var battle_id = str(player_local.player_id) + "_" + str(current_target_id)
	
	# 3. Create the starting Battle Data
	var battle_data = {
		"player_a": current_target_id, # The person who sent the request
		"player_b": player_local.player_id, # Us (the person who accepted)
		"status": "active",
		"current_turn": current_target_id # Let the challenger go first!
	}
	
	# 4. Save the Battle Session to Firebase
	var battle_url = FirebaseUrls._get_battle_url(battle_id)
	var json_data = JSON.stringify(battle_data)
	combat_requester.request(battle_url, ["Content-Type: application/json"], HTTPClient.METHOD_PUT, json_data)
	
	# 5. Update the original request to tell Player A we accepted!
	var request_update = {
		"sender_id": current_target_id,
		"status": "accepted",
		"battle_id": battle_id
	}
	var req_url = FirebaseUrls._get_combat_request_url(player_local.player_id, str(current_target_id))
	
	accept_requester.request(req_url, ["Content-Type: application/json"], HTTPClient.METHOD_PUT, JSON.stringify(request_update))
	# 6. Change our local state and show the Battle UI
	inbox_timer.stop() # Stop checking the inbox
	inbox_requester.cancel_request()
	inbox_requester.request_completed.disconnect(_on_inbox_checked) # Clean up the listener
	
	in_combat = true
	combat_ui.show_battle(true)
	
func _on_combat_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		print("Firebase confirmed receipt of combat request!")
	else:
		printerr("Error sending request to Firebase. HTTP Code: ", response_code)
func _check_inbox() -> void:
	# Don't check if we are already fighting
	if in_combat or player_local == null:
		return
		
	var url = FirebaseUrls._get_combat_inbox_url(player_local.player_id)
	inbox_requester.request(url)

func _on_inbox_checked(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return
		
	var json_str = body.get_string_from_utf8()
	
	# If the inbox is empty or doesn't exist yet
	if json_str == "null" or json_str == "":
		combat_ui.show_incoming(false)
		return
		
	var inbox_data = JSON.parse_string(json_str)
	if typeof(inbox_data) == TYPE_DICTIONARY:
		var has_pending = false
		
		# Loop through all requests in our inbox
		for sender_id in inbox_data.keys():
			var req = inbox_data[sender_id]
			if req.get("status") == "pending":
				has_pending = true
				current_target_id = int(sender_id) # Remember who is challenging us
				break # Just handle the first request we see for now
				
		if has_pending:
			combat_ui.show_incoming(true)
		else:
			combat_ui.show_incoming(false)
func _on_decline_pressed() -> void:
	print("Declining request from: ", current_target_id)
	
	# 1. Hide the UI instantly so it feels responsive
	combat_ui.show_incoming(false)
	
	# 2. Delete the request from OUR inbox in Firebase
	# Target = us (player_local), Request Key = them (current_target_id)
	var url = FirebaseUrls._get_combat_request_url(player_local.player_id, str(current_target_id))
	combat_requester.request(url, [], HTTPClient.METHOD_DELETE)
	
	# Reset target so we can request someone else
	current_target_id = -1
