extends Control
# Inventory UI - Shows collected items with tooltips

var grid_container
var tooltip_panel
var tooltip_label

var inventory_manager
var slot_size = Vector2(64, 64)

func _ready():
	# Get references to child nodes
	grid_container = get_node("Panel/MarginContainer/GridContainer")
	tooltip_panel = get_node("TooltipPanel")
	tooltip_label = get_node("TooltipPanel/TooltipLabel")
	
	# Safety check
	if not grid_container:
		print("ERROR: GridContainer not found! Check scene structure.")
		return
	
	# Get inventory manager
	inventory_manager = get_node("/root/InventoryManager")
	
	if inventory_manager:
		inventory_manager.inventory_updated.connect(_on_inventory_updated)
	
	# Hide tooltip initially
	tooltip_panel.visible = false
	
	# Initial display
	update_inventory_display()

func _on_inventory_updated():
	update_inventory_display()

func update_inventory_display():
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	if not inventory_manager:
		return
	
	# Get all items
	var items = inventory_manager.get_all_items()
	
	# Create slot for each item
	for item_name in items:
		var item_info = items[item_name]
		var item_data = item_info["data"]
		var quantity = item_info["quantity"]
		
		create_item_slot(item_data, quantity)
		

func create_item_slot(item_data: ItemData, quantity: int):
	# Create panel for slot
	var slot_panel = Panel.new()
	slot_panel.custom_minimum_size = slot_size
	slot_panel.mouse_filter = Control.MOUSE_FILTER_PASS  # Accept mouse events
	
	# Create container for proper layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Pass through to parent panel
	slot_panel.add_child(margin)
	
	# Add icon if available
	var item_icon = _load_item_icon(item_data)
	if item_icon:
		var icon = TextureRect.new()
		icon.texture = item_icon
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(icon)
	else:
		var color_rect = ColorRect.new()
		color_rect.color = Color(0.35, 0.35, 0.4)
		color_rect.custom_minimum_size = Vector2(56, 56)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(color_rect)

	# Add quantity label
	var quantity_label = Label.new()
	quantity_label.text = str(quantity)
	quantity_label.add_theme_font_size_override("font_size", 16)
	quantity_label.position = Vector2(4, 44)
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(quantity_label)

	slot_panel.mouse_entered.connect(_on_slot_hover.bind(item_data))
	slot_panel.mouse_exited.connect(_on_slot_unhover)
	
	grid_container.add_child(slot_panel)
	
	if item_data is EquipmentData:
		slot_panel.gui_input.connect(_on_slot_gui_input.bind(item_data))

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

func _on_slot_hover(item_data: ItemData):
	# Show tooltip
	tooltip_panel.visible = true
	tooltip_label.text = get_item_tooltip(item_data)
	
	# Position near mouse
	update_tooltip_position()

func _on_slot_unhover():
	tooltip_panel.visible = false

func update_tooltip_position():
	# Position tooltip near mouse cursor
	var mouse_pos = get_global_mouse_position()
	tooltip_panel.global_position = mouse_pos + Vector2(15, 15)

func _process(_delta):
	# Keep tooltip following mouse while visible
	if tooltip_panel.visible:
		update_tooltip_position()

func get_item_tooltip(item_data: ItemData) -> String:
	var text = item_data.item_name + "\n"
	text += item_data.description + "\n"
	text += "Type: " + item_data.item_type
	return text
	
func _on_slot_gui_input(event: InputEvent, item: ItemData):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			equip_item(item)

func equip_item(item: ItemData):
	if not item is EquipmentData:
		return
	var equipment_manager = get_node_or_null("/root/EquipmentManager")
	if equipment_manager:
		inventory_manager.remove_item(item.item_name, 1)
		equipment_manager.equip_item(item as EquipmentData)
		update_inventory_display()
