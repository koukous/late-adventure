extends CanvasLayer

@onready var health_ui = $HealthUI
@onready var inventory_ui = $InventoryUI
@onready var equipment_ui = $EquipmentUI  # ← THIS LINE

func _ready():
	if inventory_ui:
		inventory_ui.visible = false
	if equipment_ui:
		equipment_ui.visible = false

func _input(event):
	# Toggle inventory
	if event.is_action_pressed("ui_inventory"):
		toggle_inventory()
	
	# Toggle equipment ← THIS BLOCK
	if event.is_action_pressed("ui_equipment"):
		toggle_equipment()

func toggle_inventory():
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible

func toggle_equipment():
	if equipment_ui:
		equipment_ui.visible = not equipment_ui.visible
