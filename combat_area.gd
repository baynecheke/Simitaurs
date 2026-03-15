extends Area2D
class_name CombatArea

# Signals for the CombatManager to listen to
signal touching_player(other_player_id: int)
signal stopped_touching_player(other_player_id: int)

# This is set by PlayerLocal (or PlayerRemote) in their _ready() function
var owner_player_id: int = -1

func _ready() -> void:
	# Listen for other areas entering this zone
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	print("CombatArea detected an entering area: ", area.name)
	
	var parent_node = area.get_parent()
	
	if parent_node == null:
		print("FAILED: parent_node is null")
		return
		
	if not parent_node.has_method("get_player_id"):
		print("FAILED: parent_node (", parent_node.name, ") does not have 'get_player_id' method")
		return
		
	var other_id: int = parent_node.get_player_id()
	
	if other_id == owner_player_id:
		print("IGNORED: Detected ourselves")
		return
		
	print("SUCCESS: Found another player with ID: ", other_id)
	touching_player.emit(other_id)

func _on_area_exited(area: Area2D) -> void:
	var parent_node = area.get_parent()
	
	if parent_node == null:
		return
		
	if not parent_node.has_method("get_player_id"):
		return
		
	var other_id: int = parent_node.get_player_id()
	
	if other_id == owner_player_id:
		return
		
	stopped_touching_player.emit(other_id)
