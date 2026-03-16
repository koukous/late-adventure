extends CanvasLayer

@onready var health_ui = $HealthUI
@onready var inventory_ui = $InventoryUI
@onready var equipment_ui = $EquipmentUI  # ← THIS LINE

func _ready():
	print("=== GlobalUI Debug ===")
	print("My name: ", name)
	print("My children count: ", get_child_count())
	
	for child in get_children():
		print("  Child: ", child.name, " (", child.get_class(), ")")
	if inventory_ui:
		inventory_ui.visible = false
	if equipment_ui:
		equipment_ui.visible = false  # ← THIS LINE
	
	print("✅ Global UI loaded")

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
		print("Inventory:", "OPEN" if inventory_ui.visible else "CLOSED")

func toggle_equipment():  # ← THIS FUNCTION
	if equipment_ui:
		equipment_ui.visible = not equipment_ui.visible
		print("Equipment:", "OPEN" if equipment_ui.visible else "CLOSED")
