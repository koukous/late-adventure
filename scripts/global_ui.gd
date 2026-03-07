extends CanvasLayer
# Global UI Manager - Works in any scene!

@onready var inventory_ui = $InventoryUI
@onready var health_ui = $HealthUI

func _ready():
	# Hide inventory at start
	if inventory_ui:
		inventory_ui.visible = false

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		toggle_inventory()

func toggle_inventory():
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible
		print("Inventory:", "OPEN" if inventory_ui.visible else "CLOSED")
