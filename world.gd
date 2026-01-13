extends Node2D

@export var player_local: PlayerLocal

func _ready() -> void:
	# Safety checks
	print("World ready. player_local =", player_local)
	if player_local == null:
		push_error("World.gd: player_local is not assigned in the inspector!")
		return

	# Connect every creature currently in the scene
	for c in get_tree().get_nodes_in_group("creature"):
		c.collected.connect(_on_creature_collected.bind(c))

func _on_creature_collected(creature_data: Dictionary, creature: Creature) -> void:
	player_local.add_creature(creature_data)

	
