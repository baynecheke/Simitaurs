extends CanvasLayer
class_name CombatUI

# We can remove the 'signal decline_pressed' completely!
signal request_pressed
signal accept_pressed
signal decline_pressed
@onready var request_btn: Button = $RequestButton
@onready var incoming_panel: Panel = $IncomingPanel

func _ready() -> void:
	# Default state: hidden 
	request_btn.hide()
	incoming_panel.hide()

	# Wire buttons 
	request_btn.pressed.connect(func(): request_pressed.emit())
	$IncomingPanel/AcceptButton.pressed.connect(func(): accept_pressed.emit())
	
	# Wire the decline button to directly hide the panel
	$IncomingPanel/DeclineButton.pressed.connect(func(): decline_pressed.emit())
	
func set_request_visible(is_visible: bool) -> void:
	request_btn.visible = is_visible
	print("Visible")

func show_incoming(is_visible: bool) -> void:
	incoming_panel.visible = is_visible

func show_battle(is_visible: bool) -> void:
	# We will implement the actual battle UI later 
	pass
