class_name ItemData
extends Resource
# Defines what an item is - can be used for any collectible

@export var item_name: String = "Item"
@export var description: String = "A basic item"
@export var icon: Texture2D  # The sprite/image for this item
@export var stack_size: int = 99  # How many can stack in one slot
@export var item_type: String = "Material"  # Material, Consumable, Equipment, etc.

# For display purposes
func get_tooltip_text() -> String:
	var tooltip = "[b]" + item_name + "[/b]\n"
	tooltip += description + "\n"
	tooltip += "[i]" + item_type + "[/i]"
	return tooltip
