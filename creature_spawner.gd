extends Node2D

@export var creature_scene: PackedScene
@export var player_local: PlayerLocal
@export var spawn_count: int = 8
@export var spawn_border: float = 64.0

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	for _i in range(spawn_count):
		_spawn_creature()

func _spawn_creature() -> void:
	if creature_scene == null:
		return
	var creature := creature_scene.instantiate() as Creature
	add_child(creature)
	creature.collected.connect(_on_creature_collected.bind(creature))
	creature.respawn_at(_get_random_spawn_position())

func _get_random_spawn_position() -> Vector2:
	var viewport_size = get_viewport().size
	var rand_x = _rng.randf_range(spawn_border, viewport_size.x - spawn_border)
	var rand_y = _rng.randf_range(spawn_border, viewport_size.y - spawn_border)
	return Vector2(rand_x, rand_y)

func _on_creature_collected(creature_id: String, creature: Creature) -> void:
	if player_local == null:
		return
	player_local.add_creature(creature_id)
	creature.mark_collected()
	creature.respawn_at(_get_random_spawn_position())
