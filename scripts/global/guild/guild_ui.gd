extends CanvasLayer
# Guild Status UI - opened by the Guild Master NPC after normal dialogue

var guild_manager
var quest_manager

# Dynamic labels
var rank_badge_label: Label
var rank_name_label: Label
var quests_label: Label
var next_rank_title: Label
var req_quests_label: Label
var req_level_label: Label
var trial_boss_label: Label
var status_label: Label

func _ready():
	visible = false
	layer = 10

	guild_manager = get_node_or_null("/root/GuildManager")
	quest_manager  = get_node_or_null("/root/QuestManager")

	_create_ui()

	if guild_manager:
		guild_manager.rank_changed.connect(_on_rank_changed)
		guild_manager.rank_up_available.connect(_on_rank_up_available)
		guild_manager.quest_completed.connect(_on_quest_completed)

func _create_ui():
	var panel = Panel.new()
	panel.size = Vector2(660, 480)
	panel.position = Vector2(290, 120)
	add_child(panel)

	# --- Title bar ---
	var title = Label.new()
	title.text = "GUILD STATUS"
	title.position = Vector2(20, 12)
	title.add_theme_font_size_override("font_size", 26)
	panel.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(616, 10)
	close_btn.size = Vector2(34, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(func(): visible = false)
	panel.add_child(close_btn)

	var sep_top = HSeparator.new()
	sep_top.position = Vector2(0, 54)
	sep_top.size = Vector2(660, 4)
	panel.add_child(sep_top)

	# --- Vertical divider ---
	var sep_vert = VSeparator.new()
	sep_vert.position = Vector2(310, 58)
	sep_vert.size = Vector2(4, 362)
	panel.add_child(sep_vert)

	# --- Left: current rank ---
	_build_left_column(panel)

	# --- Right: next rank requirements ---
	_build_right_column(panel)

	# --- Bottom status bar ---
	var sep_bot = HSeparator.new()
	sep_bot.position = Vector2(0, 428)
	sep_bot.size = Vector2(660, 4)
	panel.add_child(sep_bot)

	status_label = Label.new()
	status_label.position = Vector2(16, 438)
	status_label.size = Vector2(628, 34)
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(status_label)

func _build_left_column(parent: Panel):
	var header = Label.new()
	header.text = "Current Rank"
	header.position = Vector2(20, 68)
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	parent.add_child(header)

	var sep = HSeparator.new()
	sep.position = Vector2(12, 90)
	sep.size = Vector2(290, 2)
	parent.add_child(sep)

	# Big rank letter badge
	var badge_bg = Panel.new()
	badge_bg.position = Vector2(105, 106)
	badge_bg.size = Vector2(100, 100)
	parent.add_child(badge_bg)

	rank_badge_label = Label.new()
	rank_badge_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rank_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_badge_label.add_theme_font_size_override("font_size", 56)
	rank_badge_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	rank_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_bg.add_child(rank_badge_label)

	rank_name_label = Label.new()
	rank_name_label.position = Vector2(20, 216)
	rank_name_label.size = Vector2(270, 30)
	rank_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_name_label.add_theme_font_size_override("font_size", 18)
	parent.add_child(rank_name_label)

	var sep2 = HSeparator.new()
	sep2.position = Vector2(12, 256)
	sep2.size = Vector2(290, 2)
	parent.add_child(sep2)

	quests_label = _make_left_label(parent, "Quests Completed: 0", Vector2(20, 268))
	_make_left_label(parent, "", Vector2(20, 300))  # placeholder spacing

func _make_left_label(parent: Panel, text: String, pos: Vector2) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 15)
	parent.add_child(lbl)
	return lbl

func _build_right_column(parent: Panel):
	var header = Label.new()
	header.text = "Progress to Next Rank"
	header.position = Vector2(326, 68)
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	parent.add_child(header)

	var sep = HSeparator.new()
	sep.position = Vector2(318, 90)
	sep.size = Vector2(330, 2)
	parent.add_child(sep)

	next_rank_title = Label.new()
	next_rank_title.position = Vector2(326, 102)
	next_rank_title.size = Vector2(318, 30)
	next_rank_title.add_theme_font_size_override("font_size", 18)
	next_rank_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	parent.add_child(next_rank_title)

	var sep2 = HSeparator.new()
	sep2.position = Vector2(318, 136)
	sep2.size = Vector2(330, 2)
	parent.add_child(sep2)

	req_quests_label = _make_req_label(parent, Vector2(326, 148))
	req_level_label  = _make_req_label(parent, Vector2(326, 196))
	trial_boss_label = _make_req_label(parent, Vector2(326, 244))

func _make_req_label(parent: Panel, pos: Vector2) -> Label:
	var lbl = Label.new()
	lbl.position = pos
	lbl.size = Vector2(318, 40)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(lbl)
	return lbl

# ---- Update ----

func update_display():
	if not guild_manager:
		return

	var rank = guild_manager.current_rank
	rank_badge_label.text = guild_manager.get_rank_letter(rank)
	rank_name_label.text  = guild_manager.get_rank_name(rank)
	quests_label.text     = "Quests Completed: " + str(guild_manager.quests_completed)

	if rank == guild_manager.Rank.S:
		next_rank_title.text    = "Maximum rank achieved!"
		req_quests_label.text   = ""
		req_level_label.text    = ""
		trial_boss_label.text   = "You are a legendary S-Rank adventurer."
		trial_boss_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		status_label.text       = "You have reached the pinnacle of the Adventurer's Guild."
		return

	var reqs      = guild_manager.get_next_rank_requirements()
	var next_rank = reqs["rank"]
	var q_cur     = reqs["quests_current"]
	var q_need    = reqs["quests_needed"]
	var l_cur     = reqs["level_current"]
	var l_need    = reqs["level_needed"]
	var boss      = reqs["trial_boss"]
	var can_up    = reqs["can_rank_up"]

	next_rank_title.text = "Next: " + next_rank

	# Quests
	var q_done = q_cur >= q_need
	req_quests_label.text = ("v " if q_done else "x ") + "Quests: " + str(q_cur) + " / " + str(q_need)
	req_quests_label.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if q_done else Color(1.0, 0.5, 0.5))

	# Level
	var l_done = l_cur >= l_need
	req_level_label.text = ("v " if l_done else "x ") + "Level: " + str(l_cur) + " / " + str(l_need)
	req_level_label.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if l_done else Color(1.0, 0.5, 0.5))

	# Trial boss
	var aq = quest_manager.active_quest if quest_manager else null
	var trial_active = aq and aq.is_trial
	var trial_done   = trial_active and quest_manager.is_active_quest_complete()

	if trial_done:
		trial_boss_label.text = "Trial boss defeated! Return to me."
		trial_boss_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	elif trial_active:
		trial_boss_label.text = "Trial: defeat " + boss
		trial_boss_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	else:
		trial_boss_label.text = "Trial boss: " + boss
		trial_boss_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

	# Bottom status
	if can_up and not trial_active:
		status_label.text = "You meet the requirements! Talk to the Guild Master to receive your trial quest."
		status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	elif trial_active and not trial_done:
		status_label.text = "Trial in progress — defeat " + boss + " then report back to the Guild Master."
		status_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	else:
		var remaining = q_need - q_cur
		status_label.text = str(remaining) + " more quest(s) needed before your rank-up trial."
		status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

func _on_rank_changed(_new_rank):
	update_display()

func _on_rank_up_available(_next_rank):
	update_display()

func _on_quest_completed():
	update_display()

func show_rank_up_celebration():
	# Flash the badge gold briefly
	var tween = create_tween()
	tween.tween_property(rank_badge_label, "modulate", Color(1.5, 1.5, 0.5), 0.2)
	tween.tween_property(rank_badge_label, "modulate", Color(1, 1, 1), 0.6)

func _input(event):
	if visible and event is InputEventKey and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
