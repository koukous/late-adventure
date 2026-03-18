extends CharacterBody2D
# Guild Master NPC - opens guild rank UI when talked to

@export var npc_name: String = "Guild Master Aldric"
@export_multiline var dialogue_lines: Array[String] = [
	"Welcome to the Adventurer's Guild.",
	"I've been watching your progress.",
	"Let me check your rank status..."
]

var current_line: int = 0
var player_in_range: bool = false
var is_talking: bool = false
var guild_ui_open: bool = false

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var interaction_area = $InteractionArea
@onready var prompt_label = $PromptLabel if has_node("PromptLabel") else null

# References
var guild_ui
var guild_manager

func _ready():
	# Connect interaction area
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
	
	# Hide prompt at start
	if prompt_label:
		prompt_label.visible = false
	
	# Get guild references
	guild_manager = get_node_or_null("/root/GuildManager")
	setup_guild_ui()

func setup_guild_ui():
	# Since it's in Autoload, use direct path
	guild_ui = get_node_or_null("/root/GuildUI")  # ← Changed!
	
	if guild_ui:
		guild_ui.visible = false
		print("Guild Master found GuildUI in Autoload")
	else:
		print("WARNING: GuildUI not found in Autoload!")

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		show_prompt()

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()
		stop_dialogue()
		close_guild_ui()

func _process(_delta):
	# Press E to talk or open guild UI
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		if not is_talking and not guild_ui_open:
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
		# End of dialogue - open guild UI
		stop_dialogue()
		open_guild_ui()
	else:
		show_dialogue()

func stop_dialogue():
	is_talking = false
	current_line = 0
	hide_dialogue()
	if player_in_range and not guild_ui_open:
		show_prompt()

func show_dialogue():
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if dialogue_ui:
		dialogue_ui.show_dialogue(npc_name, dialogue_lines[current_line])

func hide_dialogue():
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if dialogue_ui:
		dialogue_ui.hide_dialogue()

func open_guild_ui():
	print("Opening Guild UI...")
	
	if not guild_ui:
		setup_guild_ui()
	
	if guild_ui:
		print("  GuildUI found!")
		print("  GuildUI visible before: ", guild_ui.visible)
		print("  GuildUI position: ", guild_ui.position)
		print("  GuildUI size: ", guild_ui.size if guild_ui is Control else "N/A")
		
		if guild_ui.has_method("update_display"):
			guild_ui.update_display()
		
		guild_ui.visible = true
		guild_ui_open = true
		
		print("  GuildUI visible after: ", guild_ui.visible)
		print("Guild UI opened!")
		
		# Show current rank in dialogue
		if guild_manager:
			var rank_name = guild_manager.get_rank_name(guild_manager.current_rank)
			print("Current rank: ", rank_name)
	else:
		print("ERROR: Guild UI not found!")

func close_guild_ui():
	if guild_ui and guild_ui_open:
		guild_ui.visible = false
		guild_ui_open = false

func show_prompt():
	if prompt_label:
		prompt_label.visible = true
		prompt_label.text = "Press E to talk"

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false

func _input(event):
	# Press ESC to close guild UI
	if guild_ui_open:
		if event.is_action_pressed("ui_cancel"):
			close_guild_ui()
			if player_in_range:
				show_prompt()
