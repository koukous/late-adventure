extends Node2D
# Attach to the QuestBoard node in GuildHallInterior.
# Player presses E near it to open the Quest Board UI.

var player_in_range: bool = false
var quest_board_ui

@onready var interaction_area = $InteractionArea
@onready var prompt_label     = $PromptLabel if has_node("PromptLabel") else null

func _ready():
	quest_board_ui = get_node_or_null("/root/QuestBoardUI")

	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	if prompt_label:
		prompt_label.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false
		if quest_board_ui:
			quest_board_ui.visible = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		if not quest_board_ui:
			quest_board_ui = get_node_or_null("/root/QuestBoardUI")
		if quest_board_ui:
			quest_board_ui.refresh()
			quest_board_ui.visible = true
