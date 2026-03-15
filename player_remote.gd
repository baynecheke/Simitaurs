extends CharacterBody2D


class_name PlayerRemote

var player_id: int
var color: Color

func update_from_event(player_data: Dictionary) -> void:
	
	player_id = int(player_data["player_id"])
	color = Color.html(player_data["color"])
	
	_move_to_target(player_data["position_x"], player_data["position_y"])
	if not is_node_ready():
		await ready

	# 3. Fix the Type Error:
	# Use the 'color' variable (Color), not player_data["color"] (String)
	%Player_Sprite.modulate = color
	%PlayerLabel.text = str(player_data["player_id"])

func _move_to_target(target_pos_x, target_pos_y) -> void:
	global_position.x = target_pos_x
	global_position.y = target_pos_y
	
func get_player_id() -> int:
	return player_id
