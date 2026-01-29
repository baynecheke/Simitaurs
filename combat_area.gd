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
	# We expect the area to be another "CombatArea" attached to a player
	var parent_node = area.get_parent()
	
	if parent_node == null:
		return
		
	# Duck-typing: Check if the parent has the function we need
	# Your PlayerLocal has this function. Ensure PlayerRemote has it too.
	if not parent_node.has_method("get_player_id"):
		return
		
	var other_id: int = parent_node.get_player_id()
	
	# Prevent detecting ourselves
	if other_id == owner_player_id:
		return
		
	# Tell the manager we found someone
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
