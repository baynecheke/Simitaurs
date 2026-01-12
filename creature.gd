extends Area2D
class_name Creature

signal collected(creature_id: String)

@export var creature_id: String = "fire"

func _ready() -> void:
	add_to_group("creature")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is PlayerLocal:
		collected.emit(creature_id)

func mark_collected() -> void:
	monitoring = false

func respawn_at(position: Vector2) -> void:
	global_position = position
	monitoring = true
