extends CharacterBody2D
class_name PlayerLocal
var inventory: Dictionary = {}

signal inventory_changed(inventory: Dictionary)

const MOVE_SPEED: float = 600
var player_id: int = randi_range(100000, 999999)
var player_color: Color = Color.from_hsv(randf(), 0.5, 1.0)

func add_creature(creature_data: Dictionary) -> void:
	var id := str(creature_data.get("id", "unknown"))
	if not inventory.has(id):
		inventory[id] = []
	(inventory[id] as Array).append(creature_data.duplicate(true))
	inventory_changed.emit(get_inventory())

# Helper you’ll want later:
func get_all_creatures() -> Array:
	var out: Array = []
	for id in inventory.keys():
		out.append_array(inventory[id])
	return out

func get_inventory() -> Dictionary:
	return inventory.duplicate(true)
	
func _ready() -> void:
	%PlayerSprite.modulate = player_color
	%PlayerLabel.text = str(player_id)
	_set_random_spawn()

func _set_random_spawn() -> void:
	var screen_size = get_viewport().size
	var spawn_border = 64
	var rand_x = randf_range(spawn_border, screen_size.x - spawn_border)
	var rand_y = randf_range(spawn_border, screen_size.y - spawn_border)
	global_position = Vector2(rand_x, rand_y)

func _physics_process(delta: float) -> void:
	var dx = Input.get_axis("move_left", "move_right")
	var dy = Input.get_axis("move_up", "move_down")
	if dx != 0 or dy != 0:
		var dir = Vector2(dx, dy).normalized()
		velocity = dir * MOVE_SPEED
	else:
		velocity = Vector2.ZERO
	move_and_slide()
