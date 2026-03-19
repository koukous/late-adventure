extends Control
# Blacksmith Crafting UI - shows recipes and allows crafting

var inventory_manager
var equipment_manager

# Available recipes
var recipes: Array[CraftingRecipe] = []

# UI elements
var main_panel: Panel
var title_label: Label
var recipe_list_container: VBoxContainer
var recipe_detail_panel: Panel
var recipe_name_label: Label
var recipe_description_label: Label
var materials_status_label: Label
var craft_button: Button

var selected_recipe: CraftingRecipe = null

func _ready():
	# IMPORTANT: Hide at start!
	visible = false
	# FIX: Root must PASS to let children work
	mouse_filter = Control.MOUSE_FILTER_PASS
	z_index = 100
	
	inventory_manager = get_node_or_null("/root/InventoryManager")
	equipment_manager = get_node_or_null("/root/EquipmentManager")
	
	create_ui()
	
	print("✅ Crafting UI ready and hidden")

func create_ui():
	# Main panel
	main_panel = Panel.new()
	main_panel.size = Vector2(700, 500)
	main_panel.position = Vector2(250, 100)
	main_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(main_panel)
	
	# Title
	title_label = Label.new()
	title_label.text = "BLACKSMITH - CRAFTING"
	title_label.position = Vector2(230, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(title_label)
	
	# Recipe list (left side)
	var list_label = Label.new()
	list_label.text = "Available Recipes:"
	list_label.position = Vector2(20, 60)
	list_label.add_theme_font_size_override("font_size", 16)
	list_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(list_label)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 90)
	scroll.size = Vector2(280, 350)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	main_panel.add_child(scroll)
	
	recipe_list_container = VBoxContainer.new()
	recipe_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(recipe_list_container)
	
	# Recipe details (right side)
	recipe_detail_panel = Panel.new()
	recipe_detail_panel.position = Vector2(320, 60)
	recipe_detail_panel.size = Vector2(360, 420)
	recipe_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(recipe_detail_panel)
	
	# Recipe name
	recipe_name_label = Label.new()
	recipe_name_label.text = "Select a recipe"
	recipe_name_label.position = Vector2(15, 15)
	recipe_name_label.add_theme_font_size_override("font_size", 20)
	recipe_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_detail_panel.add_child(recipe_name_label)
	
	# Recipe description
	recipe_description_label = Label.new()
	recipe_description_label.position = Vector2(15, 50)
	recipe_description_label.size = Vector2(330, 150)
	recipe_description_label.add_theme_font_size_override("font_size", 14)
	recipe_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	recipe_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_detail_panel.add_child(recipe_description_label)
	
	# Materials status
	materials_status_label = Label.new()
	materials_status_label.position = Vector2(15, 220)
	materials_status_label.size = Vector2(330, 120)
	materials_status_label.add_theme_font_size_override("font_size", 14)
	materials_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recipe_detail_panel.add_child(materials_status_label)
	
	# Craft button
	craft_button = Button.new()
	craft_button.text = "CRAFT"
	craft_button.position = Vector2(120, 360)
	craft_button.size = Vector2(120, 40)
	craft_button.disabled = true
	craft_button.mouse_filter = Control.MOUSE_FILTER_STOP
	craft_button.pressed.connect(_on_craft_button_pressed)
	recipe_detail_panel.add_child(craft_button)

func clear_recipes():
	recipes.clear()
	
	# Clear recipe list buttons
	for child in recipe_list_container.get_children():
		child.queue_free()
	
	# Clear selection
	selected_recipe = null
	update_recipe_details()

func add_recipe(recipe: CraftingRecipe):
	if recipe and not recipes.has(recipe):
		recipes.append(recipe)

func update_recipe_list():
	# Clear existing buttons
	for child in recipe_list_container.get_children():
		child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Create button for each recipe
	for i in recipes.size():
		var recipe = recipes[i]
		
		var btn = Button.new()
		btn.text = recipe.recipe_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.focus_mode = Control.FOCUS_ALL
		
		# Use pressed signal
		btn.pressed.connect(_on_recipe_selected.bind(recipe))
		
		# Color code based on can craft
		if inventory_manager and recipe.can_craft(inventory_manager, 0, 1):
			btn.modulate = Color(0.7, 1, 0.7)
		else:
			btn.modulate = Color(1, 0.7, 0.7)
		
		recipe_list_container.add_child(btn)

func _on_recipe_selected(recipe: CraftingRecipe):
	selected_recipe = recipe
	update_recipe_details()

func update_recipe_details():
	if not selected_recipe:
		recipe_name_label.text = "Select a recipe"
		recipe_description_label.text = ""
		materials_status_label.text = ""
		craft_button.disabled = true
		return
	
	# Show recipe info
	recipe_name_label.text = selected_recipe.recipe_name
	recipe_description_label.text = selected_recipe.get_recipe_description()
	
	# Show materials status
	if inventory_manager:
		materials_status_label.text = "Materials:\n" + selected_recipe.get_material_status(inventory_manager)
		
		# Enable/disable craft button
		var can_craft = selected_recipe.can_craft(inventory_manager, 0, 1)
		craft_button.disabled = not can_craft
		
		if can_craft:
			craft_button.text = "CRAFT ✓"
			craft_button.modulate = Color(0.7, 1, 0.7)
		else:
			craft_button.text = "CRAFT (Missing Materials)"
			craft_button.modulate = Color(1, 1, 1)

func _on_craft_button_pressed():
	if not selected_recipe or not inventory_manager:
		print("ERROR: No recipe or inventory manager")
		return
	
	# Check if can craft
	if not selected_recipe.can_craft(inventory_manager, 0, 1):
		print("Cannot craft - missing materials!")
		return
	
	# Use the recipe's consume_materials function
	if selected_recipe.consume_materials(inventory_manager):
		# Add result to inventory
		inventory_manager.add_item(selected_recipe.result_item, selected_recipe.result_quantity)
		
		print("✓ Crafted: ", selected_recipe.result_item.item_name, " x", selected_recipe.result_quantity)
		
		# Update displays
		update_recipe_list()
		update_recipe_details()
		
		# Show success message
		show_craft_success()
	else:
		print("✗ Crafting failed!")

func show_craft_success():
	# Simple success message
	var success_label = Label.new()
	success_label.text = "✓ Crafted Successfully!"
	success_label.position = Vector2(100, 320)
	success_label.add_theme_font_size_override("font_size", 16)
	success_label.add_theme_color_override("font_color", Color(0, 1, 0))
	recipe_detail_panel.add_child(success_label)
	
	# Remove after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if success_label:
		success_label.queue_free()

func refresh_display():
	update_recipe_list()
	update_recipe_details()

# Block keyboard input from reaching the game world while the UI is open
func _input(event):
	if visible and event is InputEventKey:
		get_viewport().set_input_as_handled()
