extends CanvasLayer
# Equipment UI - C key to open, shows equipped items and character stats

var equipment_manager
var inventory_manager

# Slot panels keyed by slot name
var slots: Dictionary = {}

# Stats labels
var str_label: Label
var dex_label: Label
var vit_label: Label
var int_label: Label
var dmg_label: Label
var def_label: Label
var hp_label: Label

const SLOT_SIZE := Vector2(80, 80)

func _load_item_icon(item_data: ItemData) -> Texture2D:
	if not item_data:
		return null
	if item_data.icon:
		return item_data.icon
	var file_name = item_data.item_name.to_lower().replace(" ", "_") + ".png"
	var path = "res://sprites/items/" + file_name
	if ResourceLoader.exists(path):
		return load(path)
	return null

# Body layout positions within the left column (width=400)
const SLOT_POSITIONS := {
	"helmet":    Vector2(160, 68),
	"weapon":    Vector2(20,  178),
	"chest":     Vector2(160, 178),
	"accessory": Vector2(300, 178),
	"legs":      Vector2(160, 288),
	"boots":     Vector2(160, 378),
}

const SLOT_LABELS := {
	"helmet":    "Helmet",
	"weapon":    "Weapon",
	"chest":     "Chest",
	"accessory": "Accessory",
	"legs":      "Legs",
	"boots":     "Boots",
}

func _ready():
	visible = false
	layer = 10

	equipment_manager = get_node_or_null("/root/EquipmentManager")
	inventory_manager = get_node_or_null("/root/InventoryManager")

	_create_ui()

	if equipment_manager:
		equipment_manager.equipment_changed.connect(_on_equipment_changed)
		equipment_manager.stats_updated.connect(_on_stats_updated)

	update_all_slots()
	update_stats_display()

func _create_ui():
	var main_panel = Panel.new()
	main_panel.size = Vector2(700, 520)
	main_panel.position = Vector2(290, 100)
	add_child(main_panel)

	# --- Title ---
	var title = Label.new()
	title.text = "EQUIPMENT"
	title.position = Vector2(20, 12)
	title.add_theme_font_size_override("font_size", 26)
	main_panel.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(656, 10)
	close_btn.size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func(): visible = false)
	main_panel.add_child(close_btn)

	var sep_top = HSeparator.new()
	sep_top.position = Vector2(0, 54)
	sep_top.size = Vector2(700, 4)
	main_panel.add_child(sep_top)

	# --- Vertical separator between slots and stats ---
	var sep_vert = VSeparator.new()
	sep_vert.position = Vector2(400, 58)
	sep_vert.size = Vector2(4, 458)
	main_panel.add_child(sep_vert)

	# --- Equipment slots (left column) ---
	for slot_key in SLOT_POSITIONS:
		var pos = SLOT_POSITIONS[slot_key]
		var label_text = SLOT_LABELS[slot_key]
		var slot_panel = _create_slot_panel(main_panel, pos, label_text, slot_key)
		slots[slot_key] = slot_panel

	# --- Stats panel (right column) ---
	_create_stats_panel(main_panel)

func _create_slot_panel(parent: Node, pos: Vector2, label_text: String, slot_key: String) -> Panel:
	var slot = Panel.new()
	slot.position = pos
	slot.size = SLOT_SIZE
	parent.add_child(slot)

	# Slot type label (small, top)
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = label_text
	type_label.position = Vector2(2, 2)
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(type_label)

	# Icon area (center of slot)
	var icon_rect = TextureRect.new()
	icon_rect.name = "IconRect"
	icon_rect.position = Vector2(8, 14)
	icon_rect.size = Vector2(64, 46)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.visible = false
	slot.add_child(icon_rect)

	# Item name label (bottom)
	var name_label = Label.new()
	name_label.name = "ItemLabel"
	name_label.text = "Empty"
	name_label.position = Vector2(2, 62)
	name_label.size = Vector2(76, 18)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(name_label)

	# Right-click to unequip
	slot.gui_input.connect(_on_slot_gui_input.bind(slot_key))

	return slot

func _create_stats_panel(parent: Node):
	var stats_title = Label.new()
	stats_title.text = "STATS"
	stats_title.position = Vector2(420, 68)
	stats_title.add_theme_font_size_override("font_size", 18)
	parent.add_child(stats_title)

	var sep = HSeparator.new()
	sep.position = Vector2(412, 94)
	sep.size = Vector2(278, 2)
	parent.add_child(sep)

	str_label = _make_stat_label(parent, "STR   +0", Vector2(420, 106))
	dex_label = _make_stat_label(parent, "DEX   +0", Vector2(420, 136))
	vit_label = _make_stat_label(parent, "VIT   +0",  Vector2(420, 166))
	int_label = _make_stat_label(parent, "INT   +0",  Vector2(420, 196))

	var sep2 = HSeparator.new()
	sep2.position = Vector2(412, 228)
	sep2.size = Vector2(278, 2)
	parent.add_child(sep2)

	dmg_label = _make_stat_label(parent, "Damage   +0",  Vector2(420, 238))
	def_label = _make_stat_label(parent, "Defense  +0",  Vector2(420, 268))
	hp_label  = _make_stat_label(parent, "Health   +0",  Vector2(420, 298))

func _make_stat_label(parent: Node, text: String, pos: Vector2) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 16)
	parent.add_child(lbl)
	return lbl

# ---- Update logic ----

func update_all_slots():
	if not equipment_manager:
		return
	var equipped = equipment_manager.get_all_equipped()
	for slot_key in slots:
		_update_slot(slot_key, equipped.get(slot_key, null))

func _on_slot_gui_input(event: InputEvent, slot_key: String):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if equipment_manager and equipment_manager.get_equipped_item(slot_key):
				equipment_manager.unequip_item(slot_key)

func _update_slot(slot_key: String, item: EquipmentData):
	var slot = slots.get(slot_key)
	if not slot:
		return

	var name_label = slot.get_node_or_null("ItemLabel")
	var icon_rect = slot.get_node_or_null("IconRect")

	if item:
		name_label.text = item.item_name
		name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
		slot.modulate = Color(1.0, 1.0, 0.85)
		if icon_rect:
			var tex = _load_item_icon(item)
			if tex:
				icon_rect.texture = tex
				icon_rect.visible = true
			else:
				icon_rect.visible = false
	else:
		name_label.text = "Empty"
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		slot.modulate = Color(1, 1, 1)
		if icon_rect:
			icon_rect.texture = null
			icon_rect.visible = false

func update_stats_display():
	if not equipment_manager:
		return
	str_label.text = "STR   +" + str(equipment_manager.total_strength)
	dex_label.text = "DEX   +" + str(equipment_manager.total_dexterity)
	vit_label.text = "VIT   +" + str(equipment_manager.total_vitality)
	int_label.text = "INT   +" + str(equipment_manager.total_intelligence)
	dmg_label.text = "Damage   +" + str(equipment_manager.total_damage)
	def_label.text = "Defense  +" + str(equipment_manager.total_defense)
	hp_label.text  = "Health   +" + str(equipment_manager.total_health)

func _on_equipment_changed(_slot: String, _item: EquipmentData):
	update_all_slots()

func _on_stats_updated():
	update_stats_display()

func _input(event):
	if visible and event is InputEventKey and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
