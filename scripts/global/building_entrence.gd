extends Area2D
# Building Entrance - handles entering interiors

@export_file("*.tscn") var interior_scene_path: String = ""
@export var building_name: String = "Building"
@export var spawn_position_in_interior: Vector2 = Vector2(320, 400)

var player_in_range: bool = false
var prompt_label: Label = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create prompt label
	create_prompt()

func create_prompt():
	prompt_label = Label.new()
	prompt_label.text = "Press E to enter"
	prompt_label.position = Vector2(-50, -80)
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.modulate = Color(1, 1, 1, 0.9)
	prompt_label.visible = false
	add_child(prompt_label)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		show_prompt()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()

func _process(_delta):
	# Press E to enter
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		enter_building()

func enter_building():
	if interior_scene_path != "":
		print("Entering ", building_name)
		
		# Get scene manager
		var scene_manager = get_node_or_null("/root/SceneManager")
		if scene_manager:
			scene_manager.change_scene(interior_scene_path, spawn_position_in_interior)
		else:
			print("ERROR: SceneManager not found! Add to Autoload.")
	else:
		print(building_name, " has no interior scene assigned")

func show_prompt():
	if prompt_label:
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
