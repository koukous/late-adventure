extends CharacterBody2D
# Blacksmith NPC - opens crafting menu when talked to

@export var npc_name: String = "Blacksmith Goran"
@export_multiline var dialogue_lines: Array[String] = [
	"Welcome to my forge, traveler.",
	"I can craft equipment for you.",
	"Bring me materials and I'll forge you weapons and armor!"
]

# Crafting recipes this blacksmith knows
@export var recipes: Array[CraftingRecipe] = []

var current_line: int = 0
var player_in_range: bool = false
var is_talking: bool = false
var crafting_ui_open: bool = false

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var interaction_area = $InteractionArea
@onready var prompt_label = $PromptLabel if has_node("PromptLabel") else null

# Reference to crafting UI
var crafting_ui

func _ready():
	# DON'T hide the blacksmith! Remove this line:
	# visible = false  ❌ REMOVED
	
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
	
	# Hide prompt at start
	if prompt_label:
		prompt_label.visible = false
	
	# Find or create crafting UI
	setup_crafting_ui()

func setup_crafting_ui():
	# Try to find existing crafting UI in scene
	crafting_ui = get_node_or_null("/root/CraftingUI")
	
	if crafting_ui:
		# IMPORTANT: Hide it at start!
		crafting_ui.visible = false
		print("Blacksmith found CraftingUI and hid it")
	else:
		print("WARNING: CraftingUI not found in Autoload!")

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		show_prompt()

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()
		stop_dialogue()
		close_crafting()

func _process(_delta):
	# Press E to talk or open crafting
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		if not is_talking and not crafting_ui_open:
			start_dialogue()
		elif is_talking:
			next_line()

func start_dialogue():
	is_talking = true
	current_line = 0
	show_dialogue()
	hide_prompt()

func next_line():
	current_line += 1
	if current_line >= dialogue_lines.size():
		# End of dialogue - open crafting menu
		stop_dialogue()
		open_crafting()
	else:
		show_dialogue()

func stop_dialogue():
	is_talking = false
	current_line = 0
	hide_dialogue()
	if player_in_range and not crafting_ui_open:
		show_prompt()

func show_dialogue():
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if dialogue_ui:
		dialogue_ui.show_dialogue(npc_name, dialogue_lines[current_line])

func hide_dialogue():
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if dialogue_ui:
		dialogue_ui.hide_dialogue()

func open_crafting():
	print("=== OPENING BLACKSMITH CRAFTING ===")
	print("Blacksmith has ", recipes.size(), " recipes")
	
	# Get crafting UI if we don't have it yet
	if not crafting_ui:
		crafting_ui = get_node_or_null("/root/BacksmithCraftingUi")
	
	if crafting_ui:
		print("CraftingUI found!")
		
		# Clear previous recipes
		if crafting_ui.has_method("clear_recipes"):
			crafting_ui.clear_recipes()
			print("Cleared old recipes")
		
		# Load recipes into UI
		print("Adding recipes to UI:")
		for recipe in recipes:
			print("  - ", recipe.recipe_name if recipe else "NULL RECIPE")
			if crafting_ui.has_method("add_recipe"):
				crafting_ui.add_recipe(recipe)
		
		# Update and show
		if crafting_ui.has_method("update_recipe_list"):
			print("Updating recipe list...")
			crafting_ui.update_recipe_list()
		
		crafting_ui.visible = true
		crafting_ui_open = true
		print("Crafting menu opened!")
	else:
		print("ERROR: Crafting UI not found!")

func close_crafting():
	if crafting_ui and crafting_ui_open:
		crafting_ui.visible = false
		crafting_ui_open = false
		print("Crafting menu closed")

func show_prompt():
	if prompt_label:
		prompt_label.visible = true
		prompt_label.text = "Press E to talk"

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false

func _input(event):
	# Press ESC or I to close crafting menu
	if crafting_ui_open:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_inventory"):
			close_crafting()
			if player_in_range:
				show_prompt()
