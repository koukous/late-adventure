extends Area2D
# Exit Door - returns to previous scene (village)

@export var return_scene_path: String = "res://scenes/village.tscn"
@export var spawn_position_in_village: Vector2 = Vector2(400, 350)

var player_in_range: bool = false
var prompt_label: Label = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	create_prompt()

func create_prompt():
	prompt_label = Label.new()
	prompt_label.text = "Press E to exit"
	prompt_label.position = Vector2(-40, -60)
	prompt_label.add_theme_font_size_override("font_size", 16)
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
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		exit_building()

func exit_building():
	print("Exiting building...")
	
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.change_scene(return_scene_path, spawn_position_in_village)
	else:
		print("ERROR: SceneManager not found!")

func show_prompt():
	if prompt_label:
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
