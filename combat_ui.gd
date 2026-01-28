extends CanvasLayer
class_name CombatUI

signal request_pressed
signal accept_pressed
signal decline_pressed
signal attack_pressed

@onready var request_button: Button = $Control/Panel/VBox/RequestCombatButton

@onready var incoming_panel: Panel = $Control/Panel/VBox/IncomingPanel
@onready var incoming_label: Label = $Control/Panel/VBox/IncomingPanel/VBox/IncomingLabel
@onready var accept_button: Button = $Control/Panel/VBox/IncomingPanel/VBox/HBox/AcceptButton
@onready var decline_button: Button = $Control/Panel/VBox/IncomingPanel/VBox/HBox/DeclineButton

@onready var battle_panel: Panel = $Control/Panel/VBox/BattlePanel
@onready var battle_status: Label = $Control/Panel/VBox/BattlePanel/VBox/BattleStatus
@onready var battle_log: RichTextLabel = $Control/Panel/VBox/BattlePanel/VBox/BattleLog
@onready var attack_button: Button = $Control/Panel/VBox/BattlePanel/VBox/AttackButton

func _ready() -> void:
	request_button.text = "Request Combat"
	accept_button.text = "Accept"
	decline_button.text = "Decline"
	attack_button.text = "Attack"

	request_button.pressed.connect(func(): request_pressed.emit())
	accept_button.pressed.connect(func(): accept_pressed.emit())
	decline_button.pressed.connect(func(): decline_pressed.emit())
	attack_button.pressed.connect(func(): attack_pressed.emit())

	incoming_panel.visible = false
	battle_panel.visible = false
	request_button.visible = false

	battle_log.bbcode_enabled = true
	battle_log.text = ""

func set_request_visible(v: bool) -> void:
	request_button.visible = v

func show_incoming(v: bool, text: String = "") -> void:
	incoming_panel.visible = v
	if v and text != "":
		incoming_label.text = text

func show_battle(v: bool) -> void:
	battle_panel.visible = v

func set_battle_text(status: String, log_line: String) -> void:
	battle_status.text = status
	if log_line != "":
		battle_log.append_text(log_line + "\n")
		battle_log.scroll_to_line(battle_log.get_line_count())

func clear_battle_log() -> void:
	battle_log.text = ""
