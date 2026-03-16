extends Node
# Global Inventory Manager

var inventory: Dictionary = {}

signal inventory_updated
signal item_added(item_name: String, quantity: int)
signal item_removed(item_name: String, quantity: int)

func _ready():
	inventory = {}

func add_item(item_data: ItemData, quantity: int = 1) -> bool:
	var item_name = item_data.item_name
	
	if inventory.has(item_name):
		inventory[item_name]["quantity"] += quantity
	else:
		inventory[item_name] = {
			"data": item_data,
			"quantity": quantity
		}
	
	print("Added ", quantity, "x ", item_name, " to inventory")
	item_added.emit(item_name, quantity)
	inventory_updated.emit()
	return true

func remove_item(item_name: String, quantity: int = 1) -> bool:
	if not inventory.has(item_name):
		return false
	
	inventory[item_name]["quantity"] -= quantity
	
	if inventory[item_name]["quantity"] <= 0:
		inventory.erase(item_name)
	
	item_removed.emit(item_name, quantity)
	inventory_updated.emit()
	return true

func has_item(item_name: String, quantity: int = 1) -> bool:
	if not inventory.has(item_name):
		return false
	return inventory[item_name]["quantity"] >= quantity

func get_item_quantity(item_name: String) -> int:
	if not inventory.has(item_name):
		return 0
	return inventory[item_name]["quantity"]

func get_all_items() -> Dictionary:
	return inventory

func clear_inventory():
	inventory.clear()
	inventory_updated.emit()
