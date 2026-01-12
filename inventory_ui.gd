extends CanvasLayer

@export var player_local: PlayerLocal

@onready var backpack_button: Button = %BackpackButton
@onready var inventory_panel: Panel = %InventoryPanel
@onready var inventory_label: Label = %InventoryLabel

func _ready() -> void:
	inventory_panel.visible = false
	backpack_button.pressed.connect(_on_backpack_pressed)
	if player_local != null:
		player_local.inventory_changed.connect(_on_inventory_changed)
		_refresh_inventory(player_local.get_inventory())

func _on_backpack_pressed() -> void:
	inventory_panel.visible = not inventory_panel.visible

func _on_inventory_changed(inventory: Dictionary) -> void:
	_refresh_inventory(inventory)

func _refresh_inventory(inventory: Dictionary) -> void:
	if inventory.is_empty():
		inventory_label.text = "No creatures yet."
		return
	var lines: Array[String] = []
	for key in inventory.keys():
		lines.append("%s: %s" % [key, inventory[key]])
	lines.sort()
	inventory_label.text = "\n".join(lines)
