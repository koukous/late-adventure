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
	# FIX: Allow mouse to reach children!
	#mouse_filter = Control.MOUSE_FILTER_PASS  # ← ADD THIS!
	#fixing the crafting menu to be visible in front
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
	main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← Pass through
	add_child(main_panel)
	
	# Title
	title_label = Label.new()
	title_label.text = "BLACKSMITH - CRAFTING"
	title_label.position = Vector2(230, 15)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← Pass through
	main_panel.add_child(title_label)
	
	# Recipe list (left side)
	var list_label = Label.new()
	list_label.text = "Available Recipes:"
	list_label.position = Vector2(20, 60)
	list_label.add_theme_font_size_override("font_size", 16)
	list_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← Pass through
	main_panel.add_child(list_label)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 90)
	scroll.size = Vector2(280, 350)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS  # ← Accept clicks
	main_panel.add_child(scroll)
	
	recipe_list_container = VBoxContainer.new()
	recipe_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← Pass to children
	scroll.add_child(recipe_list_container)
	
	# Recipe details (right side)
	recipe_detail_panel = Panel.new()
	recipe_detail_panel.position = Vector2(320, 60)
	recipe_detail_panel.size = Vector2(360, 420)
	recipe_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← Pass through
	main_panel.add_child(recipe_detail_panel)
	
	# Recipe name
	recipe_name_label = Label.new()
	recipe_name_label.text = "Select a recipe"
	recipe_name_label.position = Vector2(15, 15)
	recipe_name_label.add_theme_font_size_override("font_size", 20)
	recipe_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← Pass through
	recipe_detail_panel.add_child(recipe_name_label)
	
	# Recipe description
	recipe_description_label = Label.new()
	recipe_description_label.position = Vector2(15, 50)
	recipe_description_label.size = Vector2(330, 150)
	recipe_description_label.add_theme_font_size_override("font_size", 14)
	recipe_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	recipe_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← Pass through
	recipe_detail_panel.add_child(recipe_description_label)
	
	# Materials status
	materials_status_label = Label.new()
	materials_status_label.position = Vector2(15, 220)
	materials_status_label.size = Vector2(330, 120)
	materials_status_label.add_theme_font_size_override("font_size", 14)
	materials_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ← Pass through
	recipe_detail_panel.add_child(materials_status_label)
	
	# Craft button
	craft_button = Button.new()
	craft_button.text = "CRAFT"
	craft_button.position = Vector2(120, 360)
	craft_button.size = Vector2(120, 40)
	craft_button.disabled = true
	craft_button.mouse_filter = Control.MOUSE_FILTER_PASS  # ← Accept clicks
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
	print("=== UPDATE RECIPE LIST ===")
	print("Number of recipes: ", recipes.size())
	
	# Clear existing buttons
	for child in recipe_list_container.get_children():
		child.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Create button for each recipe
	for recipe in recipes:
		print("Creating button for recipe: ", recipe.recipe_name)
		
		var btn = Button.new()
		btn.text = recipe.recipe_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		
		# Connect BOTH signals
		btn.pressed.connect(_on_recipe_selected.bind(recipe))
		btn.gui_input.connect(_on_button_gui_input.bind(recipe))  # ← ADD THIS
		
		# Make sure button can receive mouse input
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.focus_mode = Control.FOCUS_ALL
		
		# Color code based on can craft
		if inventory_manager and recipe.can_craft(inventory_manager, 0, 1):
			btn.modulate = Color(0.7, 1, 0.7)
		else:
			btn.modulate = Color(1, 0.7, 0.7)
		
		recipe_list_container.add_child(btn)
		
		print("  Button added")
		print("  - Position: ", btn.position)
		print("  - Global Position: ", btn.global_position)
	
	print("Recipe list updated with ", recipes.size(), " recipes")

# ADD THIS NEW FUNCTION
func _on_button_gui_input(event: InputEvent, recipe: CraftingRecipe):
	print("🔥 Button GUI input: ", event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("  ✅✅✅ BUTTON CLICKED! Recipe: ", recipe.recipe_name)
		_on_recipe_selected(recipe)  # Manually trigger the selection

func _on_recipe_selected(recipe: CraftingRecipe):
	selected_recipe = recipe
	update_recipe_details()
	print("Selected recipe: ", recipe.recipe_name)

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
	
	# Show materials status (using the recipe's built-in function!)
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

# Call this when inventory changes to update materials display
func refresh_display():
	update_recipe_list()
	update_recipe_details()

# Add this at the bottom of your script

# Override this to detect ALL mouse motion
func _process(_delta):
	if visible:
		var mouse_pos = get_global_mouse_position()
		# Check if mouse is over main panel area
		if main_panel:
			var panel_rect = Rect2(main_panel.global_position, main_panel.size)
			if panel_rect.has_point(mouse_pos):
				# Mouse is over panel - check buttons
				for child in recipe_list_container.get_children():
					if child is Button:
						var btn_rect = Rect2(child.global_position, child.size)
						if btn_rect.has_point(mouse_pos):
							print("🎯 Mouse is over button: ", child.text)

# Try overriding unhandled input
func _unhandled_input(event):
	if visible and event is InputEventMouseButton and event.pressed:
		print("⚡ CraftingUI received unhandled mouse click at: ", event.position)
		
		# Check if click is on a button
		for child in recipe_list_container.get_children():
			if child is Button:
				var btn_rect = Rect2(child.global_position, child.size)
				if btn_rect.has_point(event.position):
					print("  ✅ Click IS on button: ", child.text)
					# Manually trigger button
					child.emit_signal("pressed")
					get_viewport().set_input_as_handled()
					return
		
		print("  ❌ Click is NOT on any button")

func _input(event):
	if visible and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("🔴 Click detected!")
		
		# Check each button
		for i in recipe_list_container.get_child_count():
			var child = recipe_list_container.get_child(i)
			if child is Button:
				var local_mouse = child.get_local_mouse_position()
				var is_inside = Rect2(Vector2.ZERO, child.size).has_point(local_mouse)
				
				print("  ", child.text, " - inside: ", is_inside)
				
				if is_inside:
					print("  ✅ BUTTON CLICKED: ", child.text)
					_on_recipe_selected(recipes[i])
					get_viewport().set_input_as_handled()
					return
