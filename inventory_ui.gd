extends CanvasLayer

@export var player_local: PlayerLocal

@onready var backpack_button: Button = %BackpackButton
@onready var inventory_panel: Panel = %InventoryPanel
@onready var inventory_label: Label = %InventoryLabel

func _ready() -> void:
	
	inventory_panel.visible = false

	backpack_button.text = "Backpack"
	backpack_button.visible = true
	inventory_panel.visible = false
	inventory_label.visible = true
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	


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
	for id in inventory.keys():
		var list: Array = inventory[id]
		for c in list:
			var name := str(c.get("name", id))
			var hp := int(c.get("hp", 0))
			var max_hp := int(c.get("max_hp", hp))
			lines.append("%s  HP %d/%d" % [name, hp, max_hp])

	lines.sort()
	inventory_label.text = "\n".join(lines)
