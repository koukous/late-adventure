extends Resource
class_name CraftingRecipe
# Crafting Recipe - defines what materials are needed to craft an item

@export var recipe_name: String = "Recipe"
@export var result_item: EquipmentData  # What you get when crafting
@export var result_quantity: int = 1

# Required materials - simple arrays
@export var material_1: ItemData
@export var material_1_quantity: int = 0

@export var material_2: ItemData
@export var material_2_quantity: int = 0

@export var material_3: ItemData
@export var material_3_quantity: int = 0

@export var gold_cost: int = 0
@export var required_level: int = 1

# Check if player has all materials
func can_craft(inventory_manager, param1, param2) -> bool:
		# Check material 1
	if material_1 and material_1_quantity > 0:
		var has = inventory_manager.get_item_quantity(material_1.item_name)
		if has < material_1_quantity:
			return false
	
	# Check material 2
	if material_2 and material_2_quantity > 0:
		var has = inventory_manager.get_item_quantity(material_2.item_name)
		if has < material_2_quantity:
			return false
	
	# Check material 3
	if material_3 and material_3_quantity > 0:
		var has = inventory_manager.get_item_quantity(material_3.item_name)
		if has < material_3_quantity:
			return false
	
	return true

func get_recipe_description() -> String:
	var text = recipe_name + "\n"
	text += "Creates: " + result_item.item_name
	if result_quantity > 1:
		text += " x" + str(result_quantity)
	text += "\n\nRequires:\n"
	
	if material_1 and material_1_quantity > 0:
		text += "- " + material_1.item_name + " x" + str(material_1_quantity) + "\n"
	
	if material_2 and material_2_quantity > 0:
		text += "- " + material_2.item_name + " x" + str(material_2_quantity) + "\n"
	
	if material_3 and material_3_quantity > 0:
		text += "- " + material_3.item_name + " x" + str(material_3_quantity) + "\n"
	
	if gold_cost > 0:
		text += "- Gold: " + str(gold_cost) + "\n"
	
	if required_level > 1:
		text += "\nRequired Level: " + str(required_level)
	
	return text

func get_material_status(inventory_manager) -> String:
	var text = ""
	
	if material_1 and material_1_quantity > 0:
		var has = inventory_manager.get_item_quantity(material_1.item_name)
		text += material_1.item_name + ": " + str(has) + "/" + str(material_1_quantity)
		if has >= material_1_quantity:
			text += " ✓\n"
		else:
			text += " ✗\n"
	
	if material_2 and material_2_quantity > 0:
		var has = inventory_manager.get_item_quantity(material_2.item_name)
		text += material_2.item_name + ": " + str(has) + "/" + str(material_2_quantity)
		if has >= material_2_quantity:
			text += " ✓\n"
		else:
			text += " ✗\n"
	
	if material_3 and material_3_quantity > 0:
		var has = inventory_manager.get_item_quantity(material_3.item_name)
		text += material_3.item_name + ": " + str(has) + "/" + str(material_3_quantity)
		if has >= material_3_quantity:
			text += " ✓\n"
		else:
			text += " ✗\n"
	
	return text

func consume_materials(inventory_manager) -> bool:
	if not can_craft(inventory_manager, 0, 1):
		return false
	
	# Remove materials
	if material_1 and material_1_quantity > 0:
		inventory_manager.remove_item(material_1.item_name, material_1_quantity)
	
	if material_2 and material_2_quantity > 0:
		inventory_manager.remove_item(material_2.item_name, material_2_quantity)
	
	if material_3 and material_3_quantity > 0:
		inventory_manager.remove_item(material_3.item_name, material_3_quantity)
	
	return true
