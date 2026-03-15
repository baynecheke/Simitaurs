extends Area2D
class_name Creature

# IMPORTANT: this must match what you emit (Dictionary)
signal collected(creature_data: Dictionary)
var _collected_lock: bool = false
@export var creature_type: String = "fire"  # like "fire", "water" later

# If true, this creature rerolls rarity on first spawn AND every respawn.
# If false, it uses the exported rarity value you set in the editor.
@export var randomize_each_spawn: bool = true
@export_range(1, 5) var rarity: int = 1

@export var respawn_delay: float = 3.0
@export var spawn_area_min: Vector2 = Vector2(50, 50)
@export var spawn_area_max: Vector2 = Vector2(1800, 1000)

# Optional: weighted rarity chances (1..5)
@export var rarity_weights: Array[float] = [55.0, 25.0, 12.0, 6.0, 2.0]

# The current rolled stats for THIS spawn
var current_stats: Dictionary = {}

# Stats DB: rarity decides name + stats.
# Add more types later as needed.
const STATS_DB := {
	"fire": {
		1: {"name": "Simitaur Ember",  "max_hp": 20, "damage": 5},
		2: {"name": "Simitaur Cinder", "max_hp": 28, "damage": 7},
		3: {"name": "Simitaur Blaze",  "max_hp": 38, "damage": 10},
		4: {"name": "Simitaur Infer",  "max_hp": 52, "damage": 14},
		5: {"name": "Simitaur Solar",  "max_hp": 70, "damage": 18},
	}
}

func _ready() -> void:
	add_to_group("creature")
	body_entered.connect(_on_body_entered)

	# First-time spawn: set stats now so it looks consistent before pickup
	_apply_spawn_stats()

func _on_body_entered(body: Node) -> void:
	if body is PlayerLocal:
		# Emit FULL data so PlayerLocal can store everything.
		if _collected_lock:
			return
		if try_catch() == true:
			print("true")
			collected.emit(_build_creature_data())
			mark_collected()
		else:
			await get_tree().create_timer(2.0).timeout
			print("two seconds later")
			return

func mark_collected() -> void:
	monitoring = false
	visible = false
	_collected_lock = true
	_start_respawn_timer()

func _start_respawn_timer() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	_respawn_random()
	
func try_catch():


	var chance = 0.5
	var roll = randf()

	if roll <= chance:
		catch_success()
		return true
	else:
		catch_failed()
		return false


func catch_success():
	print("success")
	return true


func catch_failed():
	print("Simitaur escaped!")
	return false
	
func _respawn_random() -> void:
	# Move somewhere random
	var x = randf_range(spawn_area_min.x, spawn_area_max.x)
	var y = randf_range(spawn_area_min.y, spawn_area_max.y)
	global_position = Vector2(x, y)

	# Reroll stats/rarity each respawn if enabled
	_apply_spawn_stats()

	monitoring = true
	visible = true
	_collected_lock = false
	print("respawned at ", global_position, " rarity=", rarity, " name=", current_stats.get("name", "?"))

# -------------------------
# Rarity/stats helpers
# -------------------------

func _apply_spawn_stats() -> void:
	if randomize_each_spawn:
		rarity = _roll_rarity_weighted(rarity_weights)

	current_stats = _get_stats_for(creature_type, rarity)

func _get_stats_for(type_key: String, r: int) -> Dictionary:
	if not STATS_DB.has(type_key):
		push_error("No creature_type in STATS_DB: %s" % type_key)
		return {"name": type_key, "max_hp": 10, "damage": 1}

	var by_rarity: Dictionary = STATS_DB[type_key]
	if not by_rarity.has(r):
		push_error("No rarity %d for type %s" % [r, type_key])
		return {"name": type_key, "max_hp": 10, "damage": 1}

	return (by_rarity[r] as Dictionary).duplicate(true)

func _build_creature_data() -> Dictionary:
	var data := current_stats.duplicate(true)
	data["type"] = creature_type
	data["rarity"] = rarity

	# current hp starts full
	data["hp"] = int(data.get("max_hp", 1))

	# placeholders for later
	data["level"] = 1
	data["uid"] = str(Time.get_unix_time_from_system()) + "-" + str(randi())

	return data

func _roll_rarity_weighted(weights: Array[float]) -> int:
	if weights.size() < 5:
		return randi_range(1, 5)

	var total := 0.0
	for w in weights:
		total += max(w, 0.0)

	var pick := randf() * total
	var running := 0.0
	for i in range(5):
		running += max(weights[i], 0.0)
		if pick <= running:
			return i + 1

	return 5
