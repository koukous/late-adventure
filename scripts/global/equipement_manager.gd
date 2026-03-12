extends Node
# Equipment Manager - handles equipped items
# Add to Autoload as "EquipmentManager"

signal equipment_changed(slot: String, item: EquipmentData)
signal stats_updated()

# Equipment slots
var equipped_items = {
	"weapon": null,
	"helmet": null,
	"chest": null,
	"legs": null,
	"boots": null,
	"accessory": null
}

# Total stat bonuses from equipment
var total_strength: int = 0
var total_dexterity: int = 0
var total_vitality: int = 0
var total_intelligence: int = 0
var total_damage: int = 0
var total_defense: int = 0
var total_health: int = 0

func _ready():
	print("✅ Equipment Manager loaded")

func equip_item(item: EquipmentData) -> bool:
	if not item:
		print("ERROR: Trying to equip null item")
		return false
	
	# Get slot name based on equipment type
	var slot = get_slot_for_type(item.equipment_type)
	
	if slot == "":
		print("ERROR: Unknown equipment type")
		return false
	
	# Unequip current item in slot (if any)
	if equipped_items[slot]:
		unequip_item(slot)
	
	# Equip new item
	equipped_items[slot] = item
	print("Equipped: ", item.item_name, " in slot: ", slot)
	
	# Update stats
	calculate_total_stats()
	
	# Emit signals
	equipment_changed.emit(slot, item)
	stats_updated.emit()
	
	return true

func unequip_item(slot: String) -> EquipmentData:
	if not equipped_items.has(slot):
		print("ERROR: Invalid slot: ", slot)
		return null
	
	var item = equipped_items[slot]
	
	if item:
		equipped_items[slot] = null
		print("Unequipped: ", item.item_name, " from slot: ", slot)
		
		# Return item to inventory
		var inventory = get_node_or_null("/root/InventoryManager")
		if inventory:
			inventory.add_item(item, 1)
		
		# Update stats
		calculate_total_stats()
		
		# Emit signals
		equipment_changed.emit(slot, null)
		stats_updated.emit()
	
	return item

func get_equipped_item(slot: String) -> EquipmentData:
	if equipped_items.has(slot):
		return equipped_items[slot]
	return null

func get_slot_for_type(type: EquipmentData.EquipmentType) -> String:
	match type:
		EquipmentData.EquipmentType.WEAPON:
			return "weapon"
		EquipmentData.EquipmentType.HELMET:
			return "helmet"
		EquipmentData.EquipmentType.CHEST:
			return "chest"
		EquipmentData.EquipmentType.LEGS:
			return "legs"
		EquipmentData.EquipmentType.BOOTS:
			return "boots"
		EquipmentData.EquipmentType.ACCESSORY:
			return "accessory"
		_:
			return ""

func calculate_total_stats():
	# Reset totals
	total_strength = 0
	total_dexterity = 0
	total_vitality = 0
	total_intelligence = 0
	total_damage = 0
	total_defense = 0
	total_health = 0
	
	# Sum up all equipped items
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item:
			total_strength += item.strength_bonus
			total_dexterity += item.dexterity_bonus
			total_vitality += item.vitality_bonus
			total_intelligence += item.intelligence_bonus
			total_damage += item.damage_bonus
			total_defense += item.defense_bonus
			total_health += item.health_bonus
	
	print("Equipment stats updated - STR:", total_strength, " DEX:", total_dexterity, 
		  " DMG:", total_damage, " DEF:", total_defense)

func get_total_damage_bonus() -> int:
	return total_damage

func get_total_defense_bonus() -> int:
	return total_defense

func get_all_equipped() -> Dictionary:
	return equipped_items.duplicate()

func has_weapon_equipped() -> bool:
	return equipped_items["weapon"] != null

func get_equipped_weapon() -> EquipmentData:
	return equipped_items["weapon"]
