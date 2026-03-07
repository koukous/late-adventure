extends CharacterBody2D
# NPC - can be talked to

@export var npc_name: String = "Villager"
@export_multiline var dialogue_lines: Array[String] = [
	"Hello, traveler!",
	"Welcome to our village.",
	"Good luck on your journey!"
]

var current_line: int = 0
var player_in_range: bool = false
var is_talking: bool = false

@onready var sprite = $Sprite2D
@onready var interaction_area = $InteractionArea
@onready var prompt_label = $PromptLabel

func _ready():
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
	
	# Hide prompt at start
	if prompt_label:
		prompt_label.visible = false

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		show_prompt()

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()
		stop_dialogue()

func _process(_delta):
	# Press E to talk
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		if not is_talking:
			start_dialogue()
		else:
			next_line()

func start_dialogue():
	is_talking = true
	current_line = 0
	show_dialogue()
	hide_prompt()

func next_line():
	current_line += 1
	if current_line >= dialogue_lines.size():
		stop_dialogue()
	else:
		show_dialogue()

func stop_dialogue():
	is_talking = false
	current_line = 0
	hide_dialogue()
	if player_in_range:
		show_prompt()

func show_dialogue():
	# Emit signal to dialogue UI
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if dialogue_ui:
		dialogue_ui.show_dialogue(npc_name, dialogue_lines[current_line])
	else:
		# Fallback: print to console
		print(npc_name, ": ", dialogue_lines[current_line])

func hide_dialogue():
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if dialogue_ui:
		dialogue_ui.hide_dialogue()

func show_prompt():
	if prompt_label:
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
