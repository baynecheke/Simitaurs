extends Node
class_name CombatManager

# 1. Assign these in the Inspector!
@export var player_local: PlayerLocal
@export var combat_ui: CombatUI

var current_target_id: int = -1
var in_combat: bool = false

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
	#combat_ui.request_pressed.connect(_on_request_pressed)
	#combat_ui.accept_pressed.connect(_on_accept_pressed)
	#combat_ui.decline_pressed.connect(_on_decline_pressed)

	# 5. Initialize UI state
	combat_ui.set_request_visible(false)
	combat_ui.show_incoming(false)
	combat_ui.show_battle(false)

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
	print("Request button clicked for target: ", current_target_id)
	# TODO: Send request to Firebase

func _on_accept_pressed() -> void:
	print("Accept pressed")
	# TODO: Create battle session

func _on_decline_pressed() -> void:
	print("Decline pressed")
	# TODO: Clear request
