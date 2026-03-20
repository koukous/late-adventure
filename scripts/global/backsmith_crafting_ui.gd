extends CanvasLayer
# Blacksmith Crafting UI

var inventory_manager

var recipes: Array[CraftingRecipe] = []
var selected_recipe: CraftingRecipe = null
var recipe_cards: Array = []  # [[Panel, CraftingRecipe], ...]
var selected_card: Panel = null

# UI elements
var main_panel: Panel
var recipe_list_container: VBoxContainer
var selected_label: Label
var craft_button: Button

func _ready():
	visible = false
	layer = 10

	inventory_manager = get_node_or_null("/root/InventoryManager")

	if inventory_manager:
		inventory_manager.inventory_updated.connect(_on_inventory_updated)

	create_ui()

func _on_inventory_updated():
	if visible:
		refresh_display()

func create_ui():
	main_panel = Panel.new()
	main_panel.size = Vector2(660, 520)
	main_panel.position = Vector2(270, 80)
	add_child(main_panel)

	# --- Title bar ---
	var title = Label.new()
	title.text = "BLACKSMITH"
	title.position = Vector2(20, 12)
	title.add_theme_font_size_override("font_size", 26)
	main_panel.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(616, 10)
	close_btn.size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func(): visible = false)
	main_panel.add_child(close_btn)

	var sep_top = HSeparator.new()
	sep_top.position = Vector2(0, 54)
	sep_top.size = Vector2(660, 4)
	main_panel.add_child(sep_top)

	# --- Scrollable recipe list ---
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 62)
	scroll.size = Vector2(640, 388)
	main_panel.add_child(scroll)

	recipe_list_container = VBoxContainer.new()
	recipe_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list_container.add_theme_constant_override("separation", 6)
	scroll.add_child(recipe_list_container)

	# --- Bottom action bar ---
	var sep_bot = HSeparator.new()
	sep_bot.position = Vector2(0, 458)
	sep_bot.size = Vector2(660, 4)
	main_panel.add_child(sep_bot)

	selected_label = Label.new()
	selected_label.text = "Select a recipe to craft"
	selected_label.position = Vector2(16, 466)
	selected_label.size = Vector2(420, 46)
	selected_label.add_theme_font_size_override("font_size", 15)
	selected_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_panel.add_child(selected_label)

	craft_button = Button.new()
	craft_button.text = "CRAFT"
	craft_button.position = Vector2(466, 464)
	craft_button.size = Vector2(176, 46)
	craft_button.add_theme_font_size_override("font_size", 18)
	craft_button.disabled = true
	craft_button.pressed.connect(_on_craft_button_pressed)
	main_panel.add_child(craft_button)

func clear_recipes():
	recipes.clear()
	recipe_cards.clear()
	selected_card = null
	for child in recipe_list_container.get_children():
		child.queue_free()
	selected_recipe = null
	update_recipe_details()

func add_recipe(recipe: CraftingRecipe):
	if recipe and not recipes.has(recipe):
		recipes.append(recipe)

func update_recipe_list():
	recipe_cards.clear()
	selected_card = null
	for child in recipe_list_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	for recipe in recipes:
		var can_craft = inventory_manager != null and recipe.can_craft(inventory_manager, 0, 1)

		# Card panel
		var card = Panel.new()
		card.custom_minimum_size = Vector2(0, 82)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.modulate = Color(0.72, 1.0, 0.72) if can_craft else Color(1.0, 0.72, 0.72)
		recipe_list_container.add_child(card)
		recipe_cards.append([card, recipe])

		# Invisible click button covering the whole card
		var click_btn = Button.new()
		click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		click_btn.flat = true
		click_btn.pressed.connect(_on_recipe_selected.bind(recipe))
		card.add_child(click_btn)

		# Recipe name
		var name_label = Label.new()
		name_label.text = recipe.recipe_name
		name_label.position = Vector2(12, 8)
		name_label.add_theme_font_size_override("font_size", 17)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_label)

		# Result line
		if recipe.result_item:
			var result_label = Label.new()
			result_label.text = "-> " + str(recipe.result_quantity) + "x " + recipe.result_item.item_name
			result_label.position = Vector2(12, 34)
			result_label.add_theme_font_size_override("font_size", 12)
			result_label.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
			result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(result_label)

		# Materials row
		var mats_label = Label.new()
		mats_label.text = _get_materials_inline(recipe)
		mats_label.position = Vector2(12, 56)
		mats_label.add_theme_font_size_override("font_size", 12)
		mats_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		mats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(mats_label)

		# Restore highlight if this was selected
		if recipe == selected_recipe:
			selected_card = card
			card.modulate = Color(1.0, 0.95, 0.55)

func _get_materials_inline(recipe: CraftingRecipe) -> String:
	var parts = []
	var mats = [
		[recipe.material_1, recipe.material_1_quantity],
		[recipe.material_2, recipe.material_2_quantity],
		[recipe.material_3, recipe.material_3_quantity],
	]
	for m in mats:
		if m[0] and m[1] > 0:
			var have = inventory_manager.get_item_quantity(m[0].item_name) if inventory_manager else 0
			var check = "v" if have >= m[1] else "x"
			parts.append(m[0].item_name + " " + str(have) + "/" + str(m[1]) + " " + check)
	return "  |  ".join(parts)

func _on_recipe_selected(recipe: CraftingRecipe):
	# Deselect previous card
	if selected_card and is_instance_valid(selected_card):
		for pair in recipe_cards:
			if pair[0] == selected_card:
				var prev_can_craft = inventory_manager != null and pair[1].can_craft(inventory_manager, 0, 1)
				selected_card.modulate = Color(0.72, 1.0, 0.72) if prev_can_craft else Color(1.0, 0.72, 0.72)
				break

	# Select new card
	selected_recipe = recipe
	selected_card = null
	for pair in recipe_cards:
		if pair[1] == recipe:
			selected_card = pair[0]
			selected_card.modulate = Color(1.0, 0.95, 0.55)
			break

	update_recipe_details()

func update_recipe_details():
	if not selected_recipe:
		selected_label.text = "Select a recipe to craft"
		craft_button.disabled = true
		craft_button.text = "CRAFT"
		craft_button.modulate = Color(1, 1, 1)
		return

	var can_craft = inventory_manager != null and selected_recipe.can_craft(inventory_manager, 0, 1)
	selected_label.text = selected_recipe.recipe_name
	craft_button.disabled = not can_craft
	craft_button.text = "CRAFT" if can_craft else "Missing Materials"
	craft_button.modulate = Color(0.55, 1, 0.55) if can_craft else Color(1, 0.55, 0.55)

func _on_craft_button_pressed():
	if not selected_recipe or not inventory_manager:
		return
	if not selected_recipe.can_craft(inventory_manager, 0, 1):
		return

	if selected_recipe.consume_materials(inventory_manager):
		inventory_manager.add_item(selected_recipe.result_item, selected_recipe.result_quantity)
		await _show_craft_flash()
		await update_recipe_list()
		update_recipe_details()

func _show_craft_flash():
	if not selected_card or not is_instance_valid(selected_card):
		return
	selected_card.modulate = Color(0.3, 1.0, 0.4)
	var label = Label.new()
	label.text = "Crafted!"
	label.position = Vector2(300, 8)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(0.1, 0.9, 0.2))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_card.add_child(label)
	await get_tree().create_timer(0.6).timeout

func refresh_display():
	await update_recipe_list()
	update_recipe_details()

func _input(event):
	if visible and event is InputEventKey and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
