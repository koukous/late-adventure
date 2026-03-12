extends ItemData
class_name EquipmentData
# Equipment item - weapons, armor, accessories

enum EquipmentType {
	WEAPON,      # Swords, axes, bows
	HELMET,      # Head armor
	CHEST,       # Body armor
	LEGS,        # Leg armor
	BOOTS,       # Feet armor
	ACCESSORY    # Rings, amulets
}

enum WeaponType {
	SWORD,
	AXE,
	SPEAR,
	BOW,
	STAFF
}

@export var equipment_type: EquipmentType = EquipmentType.WEAPON
@export var weapon_type: WeaponType = WeaponType.SWORD

# Stats bonuses when equipped
@export var strength_bonus: int = 0
@export var dexterity_bonus: int = 0
@export var vitality_bonus: int = 0
@export var intelligence_bonus: int = 0

@export var damage_bonus: int = 0      # For weapons
@export var defense_bonus: int = 0     # For armor
@export var health_bonus: int = 0      # HP increase

@export var required_level: int = 1    # Level needed to equip

func get_equipment_tooltip() -> String:
	var text = item_name + "\n"
	text += description + "\n"
	text += "Type: " + get_equipment_type_name() + "\n"
	
	# Show stats
	if strength_bonus > 0:
		text += "STR: +" + str(strength_bonus) + "\n"
	if dexterity_bonus > 0:
		text += "DEX: +" + str(dexterity_bonus) + "\n"
	if vitality_bonus > 0:
		text += "VIT: +" + str(vitality_bonus) + "\n"
	if intelligence_bonus > 0:
		text += "INT: +" + str(intelligence_bonus) + "\n"
	
	if damage_bonus > 0:
		text += "Damage: +" + str(damage_bonus) + "\n"
	if defense_bonus > 0:
		text += "Defense: +" + str(defense_bonus) + "\n"
	if health_bonus > 0:
		text += "Health: +" + str(health_bonus) + "\n"
	
	if required_level > 1:
		text += "Required Level: " + str(required_level)
	
	return text

func get_equipment_type_name() -> String:
	match equipment_type:
		EquipmentType.WEAPON:
			return get_weapon_type_name()
		EquipmentType.HELMET:
			return "Helmet"
		EquipmentType.CHEST:
			return "Chest Armor"
		EquipmentType.LEGS:
			return "Leg Armor"
		EquipmentType.BOOTS:
			return "Boots"
		EquipmentType.ACCESSORY:
			return "Accessory"
		_:
			return "Equipment"

func get_weapon_type_name() -> String:
	match weapon_type:
		WeaponType.SWORD:
			return "Sword"
		WeaponType.AXE:
			return "Axe"
		WeaponType.SPEAR:
			return "Spear"
		WeaponType.BOW:
			return "Bow"
		WeaponType.STAFF:
			return "Staff"
		_:
			return "Weapon"
