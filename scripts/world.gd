extends Node2D
# Level/World script - handles inventory toggle

var inventory_ui = null

func _ready():
	# Try to find InventoryUI node
	var children = get_children()
	for child in children:
		if child.name == "InventoryUI":
			inventory_ui = child
			inventory_ui.visible = false
			print("✅ InventoryUI found and hidden")
			break
	
	if not inventory_ui:
		print("⚠️ WARNING: InventoryUI not found!")
		print("Make sure you added inventory_ui.tscn to this scene")

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		toggle_inventory()

func toggle_inventory():
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible
		print("Inventory toggled: ", "OPEN" if inventory_ui.visible else "CLOSED")
	else:
		print("❌ Cannot toggle - InventoryUI not in scene!")
