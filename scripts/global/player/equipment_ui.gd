extends Control
# Equipment UI - shows equipped items and allows equipping/unequipping

var equipment_manager
var inventory_manager

# Equipment slot panels
var weapon_slot
var helmet_slot
var chest_slot
var legs_slot
var boots_slot
var accessory_slot

# Stats labels
var stats_panel
var str_label
var dex_label
var vit_label
var int_label
var dmg_label
var def_label

func _ready():
	# Get managers
	equipment_manager = get_node_or_null("/root/EquipmentManager")
	inventory_manager = get_node_or_null("/root/InventoryManager")
	
	if not equipment_manager:
		print("ERROR: EquipmentManager not found!")
		return
	
	# Get UI nodes
	find_ui_nodes()
	
	# Connect signals
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
		equipment_manager.stats_updated.connect(_on_stats_updated)
	
	# Initial display
	update_all_slots()
	update_stats_display()
	
	# DEBUG: Print scene tree
	print("=== EQUIPMENT UI SCENE TREE ===")
	print_node_tree(self)

func print_node_tree(node: Node, indent: String = "") -> void:
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_node_tree(child, indent + "  ")

func find_ui_nodes():
	# Find equipment slots
	weapon_slot = get_node_or_null("Panel/SlotsContainer/WeaponSlot")
	helmet_slot = get_node_or_null("Panel/SlotsContainer/HelmetSlot")
	chest_slot = get_node_or_null("Panel/SlotsContainer/ChestSlot")
	legs_slot = get_node_or_null("Panel/SlotsContainer/LegsSlot")
	boots_slot = get_node_or_null("Panel/SlotsContainer/BootsSlot")
	accessory_slot = get_node_or_null("Panel/SlotsContainer/AccessorySlot")
	
	# DEBUG: Check if nodes found
	print("=== Equipment UI Nodes ===")
	print("WeaponSlot found:", weapon_slot != null)
	print("HelmetSlot found:", helmet_slot != null)
	
	# Find stats panel
	stats_panel = get_node_or_null("StatsPanel")
	print("StatsPanel found:", stats_panel != null)
	
	if stats_panel:
		str_label = stats_panel.get_node_or_null("StrLabel")
		dex_label = stats_panel.get_node_or_null("DexLabel")
		vit_label = stats_panel.get_node_or_null("VitLabel")
		int_label = stats_panel.get_node_or_null("IntLabel")
		dmg_label = stats_panel.get_node_or_null("DmgLabel")
		def_label = stats_panel.get_node_or_null("DefLabel")
		
		# DEBUG
		print("StrLabel found:", str_label != null)
		print("DmgLabel found:", dmg_label != null)

func update_all_slots():
	if not equipment_manager:
		return
	
	var equipped = equipment_manager.get_all_equipped()
	
	update_slot_display(weapon_slot, equipped["weapon"], "Weapon")
	update_slot_display(helmet_slot, equipped["helmet"], "Helmet")
	update_slot_display(chest_slot, equipped["chest"], "Chest")
	update_slot_display(legs_slot, equipped["legs"], "Legs")
	update_slot_display(boots_slot, equipped["boots"], "Boots")
	update_slot_display(accessory_slot, equipped["accessory"], "Accessory")

func update_slot_display(slot_panel, item: EquipmentData, slot_name: String):
	if not slot_panel:
		return
	
	# Clear existing display
	for child in slot_panel.get_children():
		if child.name != "SlotLabel":
			child.queue_free()
	
	# Get or create slot label
	var label = slot_panel.get_node_or_null("SlotLabel")
	if not label:
		label = Label.new()
		label.name = "SlotLabel"
		label.text = slot_name
		label.position = Vector2(5, 5)
		label.add_theme_font_size_override("font_size", 12)
		slot_panel.add_child(label)
	
	if item:
		# Show equipped item
		if item.icon:
			var icon = TextureRect.new()
			icon.texture = item.icon
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(48, 48)
			icon.position = Vector2(8, 25)
			slot_panel.add_child(icon)
		
		# Item name
		var name_label = Label.new()
		name_label.text = item.item_name
		name_label.position = Vector2(5, 75)
		name_label.add_theme_font_size_override("font_size", 10)
		slot_panel.add_child(name_label)

func update_stats_display():
	if not equipment_manager:
		return
	
	if str_label:
		str_label.text = "STR: +" + str(equipment_manager.total_strength)
	if dex_label:
		dex_label.text = "DEX: +" + str(equipment_manager.total_dexterity)
	if vit_label:
		vit_label.text = "VIT: +" + str(equipment_manager.total_vitality)
	if int_label:
		int_label.text = "INT: +" + str(equipment_manager.total_intelligence)
	if dmg_label:
		dmg_label.text = "Damage: +" + str(equipment_manager.total_damage)
	if def_label:
		def_label.text = "Defense: +" + str(equipment_manager.total_defense)

func _on_equipment_changed(slot: String, item: EquipmentData):
	update_all_slots()

func _on_stats_updated():
	update_stats_display()

# Called when player clicks on inventory item to equip
func try_equip_from_inventory(item: ItemData):
	if not item is EquipmentData:
		print("Item is not equipment!")
		return
	
	var equipment = item as EquipmentData
	
	# Remove from inventory
	if inventory_manager:
		inventory_manager.remove_item(item.item_name, 1)
	
	# Equip
	if equipment_manager:
		equipment_manager.equip_item(equipment)
