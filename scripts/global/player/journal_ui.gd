extends CanvasLayer
# Journal UI - J to toggle

var quest_manager
var guild_manager

# ---- Active Quest tab ----
@onready var no_quest_label      = $"MainPanel/Tabs/ActiveQuestTab/VBox/NoQuestLabel"
@onready var quest_name_label    = $"MainPanel/Tabs/ActiveQuestTab/VBox/QuestNameLabel"
@onready var type_badge_label    = $"MainPanel/Tabs/ActiveQuestTab/VBox/TypeBadgeLabel"
@onready var sep1                = $"MainPanel/Tabs/ActiveQuestTab/VBox/Sep1"
@onready var desc_label          = $"MainPanel/Tabs/ActiveQuestTab/VBox/DescLabel"
@onready var sep2                = $"MainPanel/Tabs/ActiveQuestTab/VBox/Sep2"
@onready var objective_title     = $"MainPanel/Tabs/ActiveQuestTab/VBox/ObjectiveTitleLabel"
@onready var objective_label     = $"MainPanel/Tabs/ActiveQuestTab/VBox/ObjectiveLabel"
@onready var progress_bar        = $"MainPanel/Tabs/ActiveQuestTab/VBox/ProgressBar"
@onready var progress_fill       = $"MainPanel/Tabs/ActiveQuestTab/VBox/ProgressBar/ProgressFill"
@onready var progress_label      = $"MainPanel/Tabs/ActiveQuestTab/VBox/ProgressLabel"
@onready var status_label        = $"MainPanel/Tabs/ActiveQuestTab/VBox/StatusLabel"
@onready var sep3                = $"MainPanel/Tabs/ActiveQuestTab/VBox/Sep3"
@onready var reward_title_label  = $"MainPanel/Tabs/ActiveQuestTab/VBox/RewardTitleLabel"
@onready var reward_label        = $"MainPanel/Tabs/ActiveQuestTab/VBox/RewardLabel"

# ---- Quest Log tab ----
@onready var count_label     = $"MainPanel/Tabs/QuestLogTab/VBox/CountLabel"
@onready var no_quests_label = $"MainPanel/Tabs/QuestLogTab/VBox/NoQuestsLabel"
@onready var quest_scroll    = $"MainPanel/Tabs/QuestLogTab/VBox/QuestScroll"
@onready var quest_log_list  = $"MainPanel/Tabs/QuestLogTab/VBox/QuestScroll/QuestLogList"

# ---- Guild Rank tab ----
@onready var badge_label            = $"MainPanel/Tabs/GuildRankTab/VBox/TopRow/BadgePanel/BadgeLabel"
@onready var rank_name_label        = $"MainPanel/Tabs/GuildRankTab/VBox/TopRow/RankInfo/RankNameLabel"
@onready var quests_completed_label = $"MainPanel/Tabs/GuildRankTab/VBox/TopRow/RankInfo/QuestsCompletedLabel"
@onready var max_rank_label         = $"MainPanel/Tabs/GuildRankTab/VBox/MaxRankLabel"
@onready var next_rank_label        = $"MainPanel/Tabs/GuildRankTab/VBox/NextRankLabel"
@onready var quest_req_label        = $"MainPanel/Tabs/GuildRankTab/VBox/QuestReqLabel"
@onready var quest_bar_fill         = $"MainPanel/Tabs/GuildRankTab/VBox/QuestProgressBar/QuestBarFill"
@onready var level_req_label        = $"MainPanel/Tabs/GuildRankTab/VBox/LevelReqLabel"
@onready var level_bar_fill         = $"MainPanel/Tabs/GuildRankTab/VBox/LevelProgressBar/LevelBarFill"
@onready var trial_boss_label       = $"MainPanel/Tabs/GuildRankTab/VBox/TrialBossLabel"
@onready var hint_label             = $"MainPanel/Tabs/GuildRankTab/VBox/HintLabel"

@onready var tabs = $"MainPanel/Tabs"

func _ready():
	visible = false
	layer = 10

	quest_manager = get_node_or_null("/root/QuestManager")
	guild_manager = get_node_or_null("/root/GuildManager")

	$MainPanel/CloseButton.pressed.connect(func(): visible = false)

	tabs.set_tab_title(0, "Active Quest")
	tabs.set_tab_title(1, "Quest Log")
	tabs.set_tab_title(2, "Guild Rank")

	if quest_manager:
		quest_manager.quest_accepted.connect(_on_quest_state_changed)
		quest_manager.quest_abandoned.connect(_on_quest_state_changed)
		quest_manager.quest_progress_updated.connect(_on_progress_updated)
		quest_manager.quest_ready_to_complete.connect(_on_quest_state_changed)
	if guild_manager:
		guild_manager.rank_changed.connect(_on_guild_changed)
		guild_manager.quest_completed.connect(_on_guild_changed)

func open():
	_refresh_current_tab()
	visible = true

func _refresh_current_tab():
	match tabs.current_tab:
		0: _refresh_active_quest()
		1: _refresh_quest_log()
		2: _refresh_guild_rank()

# ---- Active Quest tab ----

func _refresh_active_quest():
	var has_quest = quest_manager != null and quest_manager.active_quest != null

	no_quest_label.visible = not has_quest
	_set_quest_widgets_visible(has_quest)

	if not has_quest:
		return

	var q    = quest_manager.active_quest
	var prog = quest_manager.active_progress
	var done = quest_manager.is_active_quest_complete()

	quest_name_label.text  = q.quest_name
	type_badge_label.text  = _type_badge(q)
	desc_label.text        = q.description
	objective_label.text   = _objective_text(q)
	progress_label.text    = str(prog) + " / " + str(q.objective_count)
	reward_label.text      = str(q.reward_gold) + " gold   |   " + str(q.reward_xp) + " xp"

	var ratio = float(prog) / float(q.objective_count) if q.objective_count > 0 else 1.0
	progress_fill.anchor_right = clampf(ratio, 0.0, 1.0)
	progress_fill.color = Color(0.2, 0.75, 0.35) if done else Color(0.25, 0.55, 0.85)

	if done:
		status_label.text = "Objective complete! Return to the Guild Master to claim your reward."
		status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	else:
		status_label.text = str(q.objective_count - prog) + " more " + q.objective_target + "(s) needed."
		status_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

func _set_quest_widgets_visible(v: bool):
	quest_name_label.visible   = v
	type_badge_label.visible   = v
	sep1.visible               = v
	desc_label.visible         = v
	sep2.visible               = v
	objective_title.visible    = v
	objective_label.visible    = v
	progress_bar.visible       = v
	progress_label.visible     = v
	status_label.visible       = v
	sep3.visible               = v
	reward_title_label.visible = v
	reward_label.visible       = v

# ---- Quest Log tab ----

func _refresh_quest_log():
	var completed = quest_manager.completed_quest_ids if quest_manager else []

	count_label.text = "Completed Quests: " + str(completed.size())
	no_quests_label.visible = completed.is_empty()
	quest_scroll.visible    = not completed.is_empty()

	# Clear previous list entries
	for child in quest_log_list.get_children():
		child.free()

	if completed.is_empty():
		return

	# Build quest id → data map
	var quest_map: Dictionary = {}
	if quest_manager:
		for q in quest_manager.available_quests:
			quest_map[q.quest_id] = q

	for qid in completed:
		var q = quest_map.get(qid, null)
		_add_log_entry(q, qid)

func _add_log_entry(q: QuestData, fallback_id: String):
	var row = Panel.new()
	row.custom_minimum_size = Vector2(0, 52)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.modulate = Color(0.85, 1.0, 0.85)
	quest_log_list.add_child(row)

	var check = Label.new()
	check.text = "v"
	check.position = Vector2(10, 6)
	check.add_theme_font_size_override("font_size", 20)
	check.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(check)

	var name_lbl = Label.new()
	name_lbl.text = q.quest_name if q else fallback_id
	name_lbl.position = Vector2(36, 6)
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_lbl)

	var obj_lbl = Label.new()
	obj_lbl.text = _objective_text(q) if q else ""
	obj_lbl.position = Vector2(36, 28)
	obj_lbl.add_theme_font_size_override("font_size", 11)
	obj_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	obj_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(obj_lbl)

# ---- Guild Rank tab ----

func _refresh_guild_rank():
	if not guild_manager:
		return

	var rank = guild_manager.current_rank
	badge_label.text            = guild_manager.get_rank_letter(rank)
	rank_name_label.text        = guild_manager.get_rank_name(rank)
	quests_completed_label.text = "Quests completed: " + str(guild_manager.quests_completed)

	var is_max = rank == guild_manager.Rank.S
	max_rank_label.visible  = is_max
	next_rank_label.visible = not is_max
	quest_req_label.visible = not is_max
	level_req_label.visible = not is_max
	trial_boss_label.visible = not is_max
	hint_label.visible       = not is_max

	if is_max:
		return

	var reqs   = guild_manager.get_next_rank_requirements()
	var q_cur  = reqs["quests_current"]
	var q_need = reqs["quests_needed"]
	var l_cur  = reqs["level_current"]
	var l_need = reqs["level_needed"]
	var boss   = reqs["trial_boss"]
	var can_up = reqs["can_rank_up"]

	next_rank_label.text = "Next: " + reqs["rank"]

	var q_done = q_cur >= q_need
	quest_req_label.text = ("v " if q_done else "x ") + "Quests: " + str(q_cur) + " / " + str(q_need)
	quest_req_label.add_theme_color_override("font_color",
		Color(0.3, 0.9, 0.4) if q_done else Color(1.0, 0.5, 0.5))
	quest_bar_fill.anchor_right = clampf(float(q_cur) / float(q_need), 0.0, 1.0)

	var l_done = l_cur >= l_need
	level_req_label.text = ("v " if l_done else "x ") + "Level: " + str(l_cur) + " / " + str(l_need)
	level_req_label.add_theme_color_override("font_color",
		Color(0.3, 0.9, 0.4) if l_done else Color(1.0, 0.5, 0.5))
	level_bar_fill.anchor_right = clampf(float(l_cur) / float(l_need), 0.0, 1.0)

	var aq           = quest_manager.active_quest if quest_manager else null
	var trial_active = aq != null and aq.is_trial
	var trial_done   = trial_active and quest_manager.is_active_quest_complete()

	if trial_done:
		trial_boss_label.text = "Defeated " + boss + "! Return to the Guild Master."
		trial_boss_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	elif trial_active:
		trial_boss_label.text = "In progress — defeat " + boss
		trial_boss_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	else:
		trial_boss_label.text = "Defeat " + boss + " to advance"
		trial_boss_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

	if can_up and not trial_active:
		hint_label.text = "You meet the requirements — speak to the Guild Master for your trial quest."
		hint_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	elif trial_active and not trial_done:
		hint_label.text = "Trial in progress. Defeat the boss then return to the Guild Master."
		hint_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	else:
		hint_label.text = str(q_need - q_cur) + " more quest(s) needed before the rank-up trial."
		hint_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))

# ---- Helpers ----

func _type_badge(q: QuestData) -> String:
	match q.objective_type:
		QuestData.ObjectiveType.KILL:    return "HUNT"
		QuestData.ObjectiveType.COLLECT: return "GATHER"
		QuestData.ObjectiveType.TRIAL:   return "TRIAL"
		QuestData.ObjectiveType.EXPLORE: return "EXPLORE"
		_: return ""

func _objective_text(q: QuestData) -> String:
	if not q: return ""
	match q.objective_type:
		QuestData.ObjectiveType.KILL:    return "Kill " + str(q.objective_count) + "x " + q.objective_target
		QuestData.ObjectiveType.COLLECT: return "Collect " + str(q.objective_count) + "x " + q.objective_target
		QuestData.ObjectiveType.TRIAL:   return "Defeat " + q.objective_target
		QuestData.ObjectiveType.EXPLORE: return "Explore " + q.objective_target
		_: return ""

# ---- Signal callbacks ----

func _on_quest_state_changed(_arg = null):
	if not visible: return
	if tabs.current_tab == 0: _refresh_active_quest()
	elif tabs.current_tab == 1: _refresh_quest_log()

func _on_progress_updated(_cur, _tot):
	if visible and tabs.current_tab == 0:
		_refresh_active_quest()

func _on_guild_changed(_arg = null):
	if visible and tabs.current_tab == 2:
		_refresh_guild_rank()

# ---- Input ----

func _input(event):
	if not event is InputEventKey:
		return
	if event.is_action_pressed("ui_journal"):
		if visible:
			visible = false
		else:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
