extends CanvasLayer
# Journal UI - press J to open
# Tabs: Active Quest | Quest Log | Guild Rank

var quest_manager
var guild_manager

const TABS = ["Active Quest", "Quest Log", "Guild Rank"]
var active_tab: String = "Active Quest"
var tab_buttons: Array = []   # [[Button, tab_name], ...]

# Per-tab content containers
var tab_containers: Dictionary = {}  # tab_name -> Control

func _ready():
	visible = false
	layer = 10

	quest_manager = get_node_or_null("/root/QuestManager")
	guild_manager = get_node_or_null("/root/GuildManager")

	_create_ui()
	_connect_signals()

func _create_ui():
	var panel = Panel.new()
	panel.size = Vector2(700, 520)
	panel.position = Vector2(290, 90)
	add_child(panel)

	# --- Title ---
	var title = Label.new()
	title.text = "JOURNAL"
	title.position = Vector2(20, 12)
	title.add_theme_font_size_override("font_size", 26)
	panel.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(656, 10)
	close_btn.size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func(): visible = false)
	panel.add_child(close_btn)

	var sep_top = HSeparator.new()
	sep_top.position = Vector2(0, 54)
	sep_top.size = Vector2(700, 4)
	panel.add_child(sep_top)

	# --- Tab bar ---
	var tab_w = int(700.0 / TABS.size())
	for i in TABS.size():
		var btn = Button.new()
		btn.text = TABS[i]
		btn.position = Vector2(i * tab_w, 58)
		btn.size = Vector2(tab_w, 36)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_tab_pressed.bind(TABS[i]))
		panel.add_child(btn)
		tab_buttons.append([btn, TABS[i]])

	var sep_tabs = HSeparator.new()
	sep_tabs.position = Vector2(0, 96)
	sep_tabs.size = Vector2(700, 4)
	panel.add_child(sep_tabs)

	# --- Content area (one container per tab) ---
	for tab_name in TABS:
		var container = Control.new()
		container.position = Vector2(0, 100)
		container.size = Vector2(700, 420)
		container.visible = (tab_name == active_tab)
		panel.add_child(container)
		tab_containers[tab_name] = container

	_highlight_active_tab()
	_build_all_tabs()

func _on_tab_pressed(tab_name: String):
	active_tab = tab_name
	for tab_name2 in tab_containers:
		tab_containers[tab_name2].visible = (tab_name2 == tab_name)
	_highlight_active_tab()
	_refresh_tab(tab_name)

func _highlight_active_tab():
	for pair in tab_buttons:
		pair[0].modulate = Color(1.0, 0.85, 0.35) if pair[1] == active_tab else Color(1, 1, 1)

# ---- Build / refresh ----

func _build_all_tabs():
	_build_active_quest_tab()
	_build_quest_log_tab()
	_build_guild_rank_tab()

func _refresh_tab(tab_name: String):
	match tab_name:
		"Active Quest": _build_active_quest_tab()
		"Quest Log":    _build_quest_log_tab()
		"Guild Rank":   _build_guild_rank_tab()

func _clear_tab(tab_name: String):
	var container = tab_containers.get(tab_name)
	if not container:
		return
	for child in container.get_children():
		child.free()

# ---- Placeholder builders (filled in next tasks) ----

func _build_active_quest_tab():
	_clear_tab("Active Quest")
	var c = tab_containers["Active Quest"]

	if not quest_manager or not quest_manager.active_quest:
		var lbl = Label.new()
		lbl.text = "No active quest.\nVisit the Quest Board in the Guild Hall to pick one up."
		lbl.position = Vector2(24, 24)
		lbl.size = Vector2(652, 60)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		c.add_child(lbl)
		return

	var q    = quest_manager.active_quest
	var prog = quest_manager.active_progress
	var done = quest_manager.is_active_quest_complete()

	# Quest name
	var name_lbl = Label.new()
	name_lbl.text = q.quest_name
	name_lbl.position = Vector2(24, 18)
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	c.add_child(name_lbl)

	# Type badge
	var type_map = {
		QuestData.ObjectiveType.KILL:    "HUNT",
		QuestData.ObjectiveType.COLLECT: "GATHER",
		QuestData.ObjectiveType.EXPLORE: "EXPLORE",
		QuestData.ObjectiveType.TRIAL:   "TRIAL",
	}
	var badge = Label.new()
	badge.text = type_map.get(q.objective_type, "QUEST")
	badge.position = Vector2(24, 52)
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	c.add_child(badge)

	var sep1 = HSeparator.new()
	sep1.position = Vector2(16, 72)
	sep1.size = Vector2(668, 2)
	c.add_child(sep1)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = q.description
	desc_lbl.position = Vector2(24, 82)
	desc_lbl.size = Vector2(652, 72)
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	c.add_child(desc_lbl)

	var sep2 = HSeparator.new()
	sep2.position = Vector2(16, 162)
	sep2.size = Vector2(668, 2)
	c.add_child(sep2)

	# Objective
	var obj_title = Label.new()
	obj_title.text = "OBJECTIVE"
	obj_title.position = Vector2(24, 172)
	obj_title.add_theme_font_size_override("font_size", 12)
	obj_title.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	c.add_child(obj_title)

	var obj_lbl = Label.new()
	obj_lbl.text = _objective_text(q)
	obj_lbl.position = Vector2(24, 192)
	obj_lbl.add_theme_font_size_override("font_size", 17)
	c.add_child(obj_lbl)

	# Progress bar background
	var bar_bg = ColorRect.new()
	bar_bg.position = Vector2(24, 228)
	bar_bg.size = Vector2(652, 22)
	bar_bg.color = Color(0.18, 0.18, 0.2)
	c.add_child(bar_bg)

	# Progress bar fill
	var fill_ratio = float(prog) / float(q.objective_count) if q.objective_count > 0 else 1.0
	var bar_fill = ColorRect.new()
	bar_fill.position = Vector2(24, 228)
	bar_fill.size = Vector2(652 * fill_ratio, 22)
	bar_fill.color = Color(0.2, 0.75, 0.35) if done else Color(0.25, 0.55, 0.85)
	c.add_child(bar_fill)

	# Progress count over bar
	var prog_lbl = Label.new()
	prog_lbl.text = str(prog) + " / " + str(q.objective_count)
	prog_lbl.position = Vector2(24, 229)
	prog_lbl.size = Vector2(652, 20)
	prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog_lbl.add_theme_font_size_override("font_size", 12)
	c.add_child(prog_lbl)

	# Status message
	var status_lbl = Label.new()
	status_lbl.position = Vector2(24, 264)
	status_lbl.size = Vector2(652, 40)
	status_lbl.add_theme_font_size_override("font_size", 15)
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	if done:
		status_lbl.text = "Objective complete! Return to the Guild Master to claim your reward."
		status_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	else:
		var remaining = q.objective_count - prog
		status_lbl.text = str(remaining) + " more " + q.objective_target + "(s) needed."
		status_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	c.add_child(status_lbl)

	var sep3 = HSeparator.new()
	sep3.position = Vector2(16, 316)
	sep3.size = Vector2(668, 2)
	c.add_child(sep3)

	# Reward preview
	var rew_title = Label.new()
	rew_title.text = "REWARD"
	rew_title.position = Vector2(24, 326)
	rew_title.add_theme_font_size_override("font_size", 12)
	rew_title.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	c.add_child(rew_title)

	var rew_lbl = Label.new()
	rew_lbl.text = str(q.reward_gold) + " gold   |   " + str(q.reward_xp) + " xp"
	rew_lbl.position = Vector2(24, 346)
	rew_lbl.add_theme_font_size_override("font_size", 16)
	rew_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	c.add_child(rew_lbl)

func _build_quest_log_tab():
	_clear_tab("Quest Log")
	var c = tab_containers["Quest Log"]

	# Header count
	var completed = quest_manager.completed_quest_ids if quest_manager else []
	var count_lbl = Label.new()
	count_lbl.text = "Completed Quests: " + str(completed.size())
	count_lbl.position = Vector2(24, 10)
	count_lbl.add_theme_font_size_override("font_size", 15)
	count_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	c.add_child(count_lbl)

	if completed.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No quests completed yet.\nAccept quests from the Quest Board in the Guild Hall."
		empty_lbl.position = Vector2(24, 48)
		empty_lbl.size = Vector2(652, 60)
		empty_lbl.add_theme_font_size_override("font_size", 15)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		c.add_child(empty_lbl)
		return

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(8, 38)
	scroll.size = Vector2(684, 374)
	c.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	# Look up quest data for each completed id
	var all_quests = quest_manager.available_quests if quest_manager else []
	var quest_map: Dictionary = {}
	for q in all_quests:
		quest_map[q.quest_id] = q

	for qid in completed:
		var q = quest_map.get(qid, null)

		var row = Panel.new()
		row.custom_minimum_size = Vector2(0, 56)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.modulate = Color(0.85, 1.0, 0.85)
		vbox.add_child(row)

		var check = Label.new()
		check.text = "v"
		check.position = Vector2(10, 8)
		check.add_theme_font_size_override("font_size", 20)
		check.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(check)

		var name_lbl = Label.new()
		name_lbl.text = q.quest_name if q else qid
		name_lbl.position = Vector2(36, 8)
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(name_lbl)

		var obj_lbl = Label.new()
		obj_lbl.text = _objective_text(q) if q else ""
		obj_lbl.position = Vector2(36, 32)
		obj_lbl.add_theme_font_size_override("font_size", 11)
		obj_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		obj_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(obj_lbl)

func _build_guild_rank_tab():
	_clear_tab("Guild Rank")
	var c = tab_containers["Guild Rank"]

	if not guild_manager:
		var lbl = Label.new()
		lbl.text = "GuildManager not found."
		lbl.position = Vector2(20, 20)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		c.add_child(lbl)
		return

	var rank      = guild_manager.current_rank
	var rank_letter = guild_manager.get_rank_letter(rank)
	var rank_name   = guild_manager.get_rank_name(rank)

	# ---- Left: rank badge + stats ----
	var badge_bg = Panel.new()
	badge_bg.position = Vector2(24, 16)
	badge_bg.size = Vector2(96, 96)
	c.add_child(badge_bg)

	var badge_lbl = Label.new()
	badge_lbl.text = rank_letter
	badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 52)
	badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_bg.add_child(badge_lbl)

	var rank_name_lbl = Label.new()
	rank_name_lbl.text = rank_name
	rank_name_lbl.position = Vector2(130, 22)
	rank_name_lbl.add_theme_font_size_override("font_size", 22)
	c.add_child(rank_name_lbl)

	var quests_lbl = Label.new()
	quests_lbl.text = "Quests completed: " + str(guild_manager.quests_completed)
	quests_lbl.position = Vector2(130, 56)
	quests_lbl.add_theme_font_size_override("font_size", 15)
	quests_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	c.add_child(quests_lbl)

	var sep1 = HSeparator.new()
	sep1.position = Vector2(16, 126)
	sep1.size = Vector2(668, 2)
	c.add_child(sep1)

	# ---- Max rank ----
	if rank == guild_manager.Rank.S:
		var max_lbl = Label.new()
		max_lbl.text = "Maximum rank achieved!\nYou are a legendary S-Rank adventurer."
		max_lbl.position = Vector2(24, 142)
		max_lbl.size = Vector2(652, 60)
		max_lbl.add_theme_font_size_override("font_size", 18)
		max_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		max_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		c.add_child(max_lbl)
		return

	# ---- Next rank requirements ----
	var next_title = Label.new()
	next_title.text = "PROGRESS TO NEXT RANK"
	next_title.position = Vector2(24, 136)
	next_title.add_theme_font_size_override("font_size", 12)
	next_title.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	c.add_child(next_title)

	var reqs   = guild_manager.get_next_rank_requirements()
	var q_cur  = reqs["quests_current"]
	var q_need = reqs["quests_needed"]
	var l_cur  = reqs["level_current"]
	var l_need = reqs["level_needed"]
	var boss   = reqs["trial_boss"]

	var next_rank_lbl = Label.new()
	next_rank_lbl.text = "Next: " + reqs["rank"]
	next_rank_lbl.position = Vector2(24, 156)
	next_rank_lbl.add_theme_font_size_override("font_size", 18)
	next_rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	c.add_child(next_rank_lbl)

	# Quest requirement + progress bar
	var q_done = q_cur >= q_need
	_add_req_row(c, Vector2(24, 194),
		("v " if q_done else "x ") + "Quests: " + str(q_cur) + " / " + str(q_need),
		float(q_cur) / float(q_need),
		Color(0.3, 0.9, 0.4) if q_done else Color(1.0, 0.5, 0.5))

	# Level requirement + progress bar
	var l_done = l_cur >= l_need
	_add_req_row(c, Vector2(24, 252),
		("v " if l_done else "x ") + "Level: " + str(l_cur) + " / " + str(l_need),
		float(l_cur) / float(l_need),
		Color(0.3, 0.9, 0.4) if l_done else Color(1.0, 0.5, 0.5))

	# Trial boss line
	var sep2 = HSeparator.new()
	sep2.position = Vector2(16, 308)
	sep2.size = Vector2(668, 2)
	c.add_child(sep2)

	var trial_title = Label.new()
	trial_title.text = "RANK-UP TRIAL"
	trial_title.position = Vector2(24, 318)
	trial_title.add_theme_font_size_override("font_size", 12)
	trial_title.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	c.add_child(trial_title)

	var aq = quest_manager.active_quest if quest_manager else null
	var trial_active = aq and aq.is_trial
	var trial_done   = trial_active and quest_manager.is_active_quest_complete()

	var boss_lbl = Label.new()
	boss_lbl.position = Vector2(24, 338)
	boss_lbl.add_theme_font_size_override("font_size", 16)
	if trial_done:
		boss_lbl.text = "Defeated " + boss + "! Return to the Guild Master."
		boss_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	elif trial_active:
		boss_lbl.text = "In progress — hunt down " + boss
		boss_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	else:
		boss_lbl.text = "Defeat " + boss + " to advance"
		boss_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	c.add_child(boss_lbl)

	# Bottom hint
	var sep3 = HSeparator.new()
	sep3.position = Vector2(16, 376)
	sep3.size = Vector2(668, 2)
	c.add_child(sep3)

	var hint = Label.new()
	hint.position = Vector2(24, 386)
	hint.size = Vector2(652, 30)
	hint.add_theme_font_size_override("font_size", 13)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	if reqs["can_rank_up"] and not trial_active:
		hint.text = "You meet the requirements — speak to the Guild Master for your trial quest."
		hint.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	elif trial_active and not trial_done:
		hint.text = "Trial in progress. Defeat the boss then return to the Guild Master."
		hint.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	else:
		var remaining = q_need - q_cur
		hint.text = str(remaining) + " more quest(s) needed before the rank-up trial becomes available."
		hint.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	c.add_child(hint)

func _add_req_row(parent: Control, pos: Vector2, label_text: String, fill: float, color: Color):
	var lbl = Label.new()
	lbl.text = label_text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

	var bar_bg = ColorRect.new()
	bar_bg.position = pos + Vector2(0, 26)
	bar_bg.size = Vector2(652, 16)
	bar_bg.color = Color(0.18, 0.18, 0.2)
	parent.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.position = pos + Vector2(0, 26)
	bar_fill.size = Vector2(652 * clampf(fill, 0.0, 1.0), 16)
	bar_fill.color = color
	parent.add_child(bar_fill)

func _objective_text(q: QuestData) -> String:
	if not q:
		return ""
	match q.objective_type:
		QuestData.ObjectiveType.KILL:    return "Kill " + str(q.objective_count) + "x " + q.objective_target
		QuestData.ObjectiveType.COLLECT: return "Collect " + str(q.objective_count) + "x " + q.objective_target
		QuestData.ObjectiveType.TRIAL:   return "Defeat " + q.objective_target
		QuestData.ObjectiveType.EXPLORE: return "Explore " + q.objective_target
		_: return ""

# ---- Signals ----

func _connect_signals():
	if quest_manager:
		quest_manager.quest_accepted.connect(_on_quest_state_changed)
		quest_manager.quest_abandoned.connect(_on_quest_state_changed)
		quest_manager.quest_progress_updated.connect(_on_progress_updated)
		quest_manager.quest_ready_to_complete.connect(_on_quest_state_changed)
	if guild_manager:
		guild_manager.rank_changed.connect(_on_guild_changed)
		guild_manager.quest_completed.connect(_on_guild_changed)

func _on_quest_state_changed(_arg = null):
	if visible:
		_refresh_tab("Active Quest")
		_refresh_tab("Quest Log")

func _on_progress_updated(_cur, _tot):
	if visible and active_tab == "Active Quest":
		_build_active_quest_tab()

func _on_guild_changed(_arg = null):
	if visible:
		_refresh_tab("Guild Rank")

# ---- Open / close ----

func open():
	_refresh_tab(active_tab)
	visible = true

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
