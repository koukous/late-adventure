extends CharacterBody2D
# Guild Master NPC
# Interaction flow:
#   - Active quest complete (normal)  → validate + give reward
#   - Active trial quest complete      → rank up
#   - Rank-up conditions met           → offer trial quest
#   - Default                          → open guild status UI

@export var npc_name: String = "Guild Master Aldric"

var player_in_range: bool = false
var is_talking: bool = false
var guild_ui_open: bool = false

var _dialogue_lines: Array[String] = []
var _current_line: int = 0
var _pending_action: String = ""   # action to run after final dialogue line

@onready var interaction_area = $InteractionArea
@onready var prompt_label     = $PromptLabel if has_node("PromptLabel") else null

var guild_ui
var guild_manager
var quest_manager

func _ready():
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)

	if prompt_label:
		prompt_label.visible = false

	guild_manager = get_node_or_null("/root/GuildManager")
	quest_manager = get_node_or_null("/root/QuestManager")
	guild_ui      = get_node_or_null("/root/GuildUI")

# ---- Player proximity ----

func _on_player_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		_show_prompt()

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		_hide_prompt()
		_stop_dialogue()
		_close_guild_ui()

# ---- Input ----

func _process(_delta):
	if not player_in_range:
		return

	if Input.is_action_just_pressed("ui_accept"):
		if guild_ui_open:
			return
		if not is_talking:
			_start_interaction()
		else:
			_advance_dialogue()

func _input(event):
	if guild_ui_open and event.is_action_pressed("ui_cancel"):
		_close_guild_ui()
		if player_in_range:
			_show_prompt()

# ---- Interaction logic ----

func _start_interaction():
	var mode = _detect_mode()
	_dialogue_lines = _build_dialogue(mode)
	_pending_action = mode
	_current_line = 0
	is_talking = true
	_hide_prompt()
	_show_dialogue(_dialogue_lines[0])

func _detect_mode() -> String:
	if not quest_manager:
		return "normal"

	var aq = quest_manager.active_quest

	# Active trial quest is complete → rank up
	if aq and aq.is_trial and quest_manager.is_active_quest_complete():
		return "trial_complete"

	# Active normal quest is complete → give reward
	if aq and not aq.is_trial and quest_manager.is_active_quest_complete():
		return "quest_complete"

	# No active quest, rank-up conditions met → offer trial
	if not aq and guild_manager and guild_manager.can_rank_up():
		var trial = quest_manager.get_trial_quest_for_rank(guild_manager.current_rank)
		if trial:
			return "trial_offer"

	return "normal"

func _build_dialogue(mode: String) -> Array[String]:
	match mode:
		"quest_complete":
			var q = quest_manager.active_quest
			return [
				"Excellent work, adventurer.",
				"You've completed \"" + q.quest_name + "\" — well done.",
				"Here are your rewards. Keep pushing your limits."
			]

		"trial_complete":
			var aq = quest_manager.active_quest
			var next_rank = guild_manager.get_rank_name(guild_manager.current_rank + 1) if guild_manager else "?"
			return [
				"Incredible. You've defeated " + aq.objective_target + ".",
				"Few adventurers reach this point.",
				"By my authority, I hereby advance you to rank " + next_rank + "!"
			]

		"trial_offer":
			var next_rank = guild_manager.get_rank_name(guild_manager.current_rank + 1) if guild_manager else "?"
			var trial = quest_manager.get_trial_quest_for_rank(guild_manager.current_rank)
			var boss = trial.objective_target if trial else "the guardian"
			return [
				"Adventurer, you've earned the right to advance.",
				"One final test remains: defeat " + boss + ".",
				"I am assigning you the rank-up trial for " + next_rank + ".",
				"Return to me after your victory."
			]

		_:  # normal
			var rank_name = guild_manager.get_rank_name(guild_manager.current_rank) if guild_manager else "F"
			return [
				"Welcome, adventurer. Current rank: " + rank_name + ".",
				"Check the quest board for available contracts.",
				"Complete enough quests and I'll grant you the rank-up trial."
			]

func _advance_dialogue():
	_current_line += 1
	if _current_line >= _dialogue_lines.size():
		_finish_dialogue()
	else:
		_show_dialogue(_dialogue_lines[_current_line])

func _finish_dialogue():
	_stop_dialogue()
	_execute_pending_action()

func _execute_pending_action():
	match _pending_action:
		"quest_complete":
			quest_manager.complete_active_quest()

		"trial_complete":
			quest_manager.complete_active_quest()  # internally calls guild_manager.rank_up()

		"trial_offer":
			var trial = quest_manager.get_trial_quest_for_rank(guild_manager.current_rank)
			if trial:
				quest_manager.accept_quest(trial)

		_:  # normal → open guild UI
			_open_guild_ui()

# ---- Dialogue display ----

func _show_dialogue(text: String):
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if dialogue_ui:
		dialogue_ui.show_dialogue(npc_name, text)

func _hide_dialogue():
	var dialogue_ui = get_node_or_null("/root/DialogueUI")
	if dialogue_ui:
		dialogue_ui.hide_dialogue()

func _stop_dialogue():
	is_talking = false
	_current_line = 0
	_pending_action = ""
	_hide_dialogue()
	if player_in_range and not guild_ui_open:
		_show_prompt()

# ---- Guild UI ----

func _open_guild_ui():
	if not guild_ui:
		guild_ui = get_node_or_null("/root/GuildUI")
	if guild_ui:
		if guild_ui.has_method("update_display"):
			guild_ui.update_display()
		guild_ui.visible = true
		guild_ui_open = true

func _close_guild_ui():
	if guild_ui and guild_ui_open:
		guild_ui.visible = false
		guild_ui_open = false

# ---- Prompt ----

func _show_prompt():
	if prompt_label:
		prompt_label.visible = true
		prompt_label.text = "Press E to talk"

func _hide_prompt():
	if prompt_label:
		prompt_label.visible = false
