extends CanvasLayer
# Quest Board UI - opened by interacting with the quest board in the guild hall

var quest_manager
var guild_manager

# UI refs
var rank_label: Label
var quest_list_container: VBoxContainer
var detail_name: Label
var detail_desc: Label
var detail_objective: Label
var detail_reward: Label
var action_button: Button
var active_bar: Panel
var active_bar_label: Label

var selected_quest: QuestData = null
var quest_cards: Array = []   # [[Panel, QuestData], ...]
var selected_card: Panel = null

var selected_zone: String = "forest"
var zone_buttons: Dictionary = {}   # zone_id -> Button
var detail_zone: Label

func _ready():
	visible = false
	layer = 10

	quest_manager = get_node_or_null("/root/QuestManager")
	guild_manager = get_node_or_null("/root/GuildManager")

	_create_ui()

	if quest_manager:
		quest_manager.quest_accepted.connect(_on_quest_state_changed)
		quest_manager.quest_abandoned.connect(_on_quest_state_changed)
		quest_manager.quest_progress_updated.connect(_on_progress_updated)
		quest_manager.quest_ready_to_complete.connect(_on_quest_state_changed)

	if guild_manager:
		guild_manager.rank_changed.connect(_on_rank_changed)

func _create_ui():
	var panel = Panel.new()
	panel.size = Vector2(700, 520)
	panel.position = Vector2(290, 90)
	add_child(panel)

	# --- Title bar ---
	var title = Label.new()
	title.text = "QUEST BOARD"
	title.position = Vector2(20, 12)
	title.add_theme_font_size_override("font_size", 26)
	panel.add_child(title)

	rank_label = Label.new()
	rank_label.position = Vector2(220, 18)
	rank_label.add_theme_font_size_override("font_size", 14)
	rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	panel.add_child(rank_label)

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

	# --- Vertical divider ---
	var sep_vert = VSeparator.new()
	sep_vert.position = Vector2(430, 58)
	sep_vert.size = Vector2(4, 398)
	panel.add_child(sep_vert)

	# --- Zone filter buttons ---
	var zones = [["forest", "Forest"], ["desert", "Desert"], ["snow_mountain", "Snow Mtn"]]
	var btn_w = 134
	for i in zones.size():
		var zid = zones[i][0]
		var zlabel = zones[i][1]
		var zbtn = Button.new()
		zbtn.text = zlabel
		zbtn.position = Vector2(8 + i * (btn_w + 2), 60)
		zbtn.size = Vector2(btn_w, 30)
		zbtn.add_theme_font_size_override("font_size", 13)
		zbtn.pressed.connect(_set_zone.bind(zid))
		panel.add_child(zbtn)
		zone_buttons[zid] = zbtn
	_update_zone_buttons()

	var sep_zone = HSeparator.new()
	sep_zone.position = Vector2(0, 94)
	sep_zone.size = Vector2(430, 2)
	panel.add_child(sep_zone)

	# --- Left: scrollable quest list ---
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(8, 98)
	scroll.size = Vector2(418, 358)
	panel.add_child(scroll)

	quest_list_container = VBoxContainer.new()
	quest_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_list_container.add_theme_constant_override("separation", 5)
	scroll.add_child(quest_list_container)

	# --- Right: quest detail panel ---
	_create_detail_panel(panel)

	# --- Bottom: active quest status bar ---
	var sep_bot = HSeparator.new()
	sep_bot.position = Vector2(0, 460)
	sep_bot.size = Vector2(700, 4)
	panel.add_child(sep_bot)

	active_bar = Panel.new()
	active_bar.position = Vector2(0, 464)
	active_bar.size = Vector2(700, 56)
	active_bar.visible = false
	panel.add_child(active_bar)

	active_bar_label = Label.new()
	active_bar_label.position = Vector2(12, 6)
	active_bar_label.size = Vector2(676, 44)
	active_bar_label.add_theme_font_size_override("font_size", 14)
	active_bar_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	active_bar.add_child(active_bar_label)

func _create_detail_panel(parent: Panel):
	detail_name = Label.new()
	detail_name.text = "Select a quest"
	detail_name.position = Vector2(442, 66)
	detail_name.size = Vector2(248, 30)
	detail_name.add_theme_font_size_override("font_size", 16)
	detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(detail_name)

	var sep = HSeparator.new()
	sep.position = Vector2(436, 100)
	sep.size = Vector2(256, 2)
	parent.add_child(sep)

	detail_desc = Label.new()
	detail_desc.position = Vector2(442, 108)
	detail_desc.size = Vector2(248, 120)
	detail_desc.add_theme_font_size_override("font_size", 12)
	detail_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(detail_desc)

	detail_objective = Label.new()
	detail_objective.position = Vector2(442, 238)
	detail_objective.size = Vector2(248, 40)
	detail_objective.add_theme_font_size_override("font_size", 13)
	detail_objective.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	detail_objective.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(detail_objective)

	detail_reward = Label.new()
	detail_reward.position = Vector2(442, 286)
	detail_reward.size = Vector2(248, 30)
	detail_reward.add_theme_font_size_override("font_size", 13)
	detail_reward.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	parent.add_child(detail_reward)

	detail_zone = Label.new()
	detail_zone.position = Vector2(442, 330)
	detail_zone.size = Vector2(248, 28)
	detail_zone.add_theme_font_size_override("font_size", 13)
	parent.add_child(detail_zone)

	action_button = Button.new()
	action_button.position = Vector2(442, 400)
	action_button.size = Vector2(248, 48)
	action_button.add_theme_font_size_override("font_size", 16)
	action_button.disabled = true
	action_button.pressed.connect(_on_action_pressed)
	parent.add_child(action_button)

# ---- Refresh ----

func refresh():
	_update_rank_label()
	_rebuild_quest_list()
	_update_active_bar()
	_update_detail_panel()

func _update_rank_label():
	if guild_manager:
		rank_label.text = "[ Rank: " + guild_manager.get_rank_name(guild_manager.current_rank) + " ]"

func _rebuild_quest_list():
	for child in quest_list_container.get_children():
		child.free()
	quest_cards.clear()
	selected_card = null

	if not quest_manager or not guild_manager:
		return

	var rank = guild_manager.current_rank
	var quests = quest_manager.get_quests_for_zone(selected_zone, rank)

	if quests.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No quests available at your rank.\nComplete more quests or rank up."
		empty_lbl.add_theme_font_size_override("font_size", 14)
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_lbl.position = Vector2(8, 8)
		quest_list_container.add_child(empty_lbl)
		return

	for quest in quests:
		var is_active = quest_manager.active_quest == quest
		_add_quest_card(quest, is_active)

func _add_quest_card(quest: QuestData, is_active: bool):
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 72)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if is_active:
		card.modulate = Color(0.7, 0.85, 1.0)
	elif quest == selected_quest:
		card.modulate = Color(1.0, 0.95, 0.55)
	else:
		card.modulate = Color(1, 1, 1)

	quest_list_container.add_child(card)
	quest_cards.append([card, quest])

	# Invisible click overlay
	var btn = Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.pressed.connect(_on_quest_selected.bind(quest))
	card.add_child(btn)

	# Quest name
	var name_lbl = Label.new()
	name_lbl.text = ("[ACTIVE] " if is_active else "") + quest.quest_name
	name_lbl.position = Vector2(10, 8)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# Objective summary
	var obj_lbl = Label.new()
	obj_lbl.text = _objective_summary(quest)
	obj_lbl.position = Vector2(10, 32)
	obj_lbl.add_theme_font_size_override("font_size", 12)
	obj_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	obj_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(obj_lbl)

	# Reward
	var rew_lbl = Label.new()
	rew_lbl.text = str(quest.reward_gold) + "g  |  " + str(quest.reward_xp) + " xp"
	rew_lbl.position = Vector2(10, 52)
	rew_lbl.add_theme_font_size_override("font_size", 11)
	rew_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	rew_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rew_lbl)

	# Zone badge (top-right of card)
	var zone_lbl = Label.new()
	zone_lbl.text = _zone_display_name(quest.zone)
	zone_lbl.position = Vector2(300, 8)
	zone_lbl.size = Vector2(110, 20)
	zone_lbl.add_theme_font_size_override("font_size", 11)
	zone_lbl.add_theme_color_override("font_color", _zone_color(quest.zone))
	zone_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(zone_lbl)

func _update_active_bar():
	if not quest_manager or not quest_manager.active_quest:
		active_bar.visible = false
		return

	active_bar.visible = true
	var q = quest_manager.active_quest
	var prog = quest_manager.active_progress
	var total = q.objective_count
	var status = "READY TO COMPLETE" if quest_manager.is_active_quest_complete() else str(prog) + " / " + str(total)
	active_bar_label.text = "Active Quest: " + q.quest_name + "   |   " + _objective_summary(q) + "   |   " + status

func _update_detail_panel():
	if not selected_quest:
		detail_name.text = "Select a quest"
		detail_desc.text = ""
		detail_objective.text = ""
		detail_reward.text = ""
		detail_zone.text = ""
		action_button.disabled = true
		action_button.text = "Accept"
		action_button.modulate = Color(1, 1, 1)
		return

	detail_name.text = selected_quest.quest_name
	detail_desc.text = selected_quest.description
	detail_objective.text = "Objective: " + _objective_summary(selected_quest)
	detail_reward.text = "Reward: " + str(selected_quest.reward_gold) + " gold  |  " + str(selected_quest.reward_xp) + " xp"
	detail_zone.text = "Zone: " + _zone_display_name(selected_quest.zone)
	detail_zone.add_theme_color_override("font_color", _zone_color(selected_quest.zone))

	var is_active = quest_manager and quest_manager.active_quest == selected_quest
	var has_other_active = quest_manager and quest_manager.active_quest != null and not is_active

	if is_active:
		action_button.text = "Abandon Quest"
		action_button.disabled = false
		action_button.modulate = Color(1.0, 0.55, 0.55)
	elif has_other_active:
		action_button.text = "Finish Active Quest First"
		action_button.disabled = true
		action_button.modulate = Color(1, 1, 1)
	else:
		action_button.text = "Accept Quest"
		action_button.disabled = false
		action_button.modulate = Color(0.55, 1.0, 0.55)

# ---- Interaction ----

func _on_quest_selected(quest: QuestData):
	# Deselect previous card
	if selected_card and is_instance_valid(selected_card):
		var was_active = quest_manager and quest_manager.active_quest == selected_quest
		selected_card.modulate = Color(0.7, 0.85, 1.0) if was_active else Color(1, 1, 1)

	selected_quest = quest
	selected_card = null
	for pair in quest_cards:
		if pair[1] == quest:
			selected_card = pair[0]
			selected_card.modulate = Color(1.0, 0.95, 0.55)
			break

	_update_detail_panel()

func _on_action_pressed():
	if not quest_manager or not selected_quest:
		return

	if quest_manager.active_quest == selected_quest:
		quest_manager.abandon_quest()
	else:
		quest_manager.accept_quest(selected_quest)

func _on_quest_state_changed(_arg = null):
	refresh()

func _on_progress_updated(_current: int, _total: int):
	_update_active_bar()

func _on_rank_changed(_new_rank):
	refresh()

# ---- Helpers ----

func _objective_summary(quest: QuestData) -> String:
	match quest.objective_type:
		QuestData.ObjectiveType.KILL:
			return "Kill " + str(quest.objective_count) + "x " + quest.objective_target
		QuestData.ObjectiveType.COLLECT:
			return "Collect " + str(quest.objective_count) + "x " + quest.objective_target
		QuestData.ObjectiveType.TRIAL:
			return "Defeat " + quest.objective_target
		QuestData.ObjectiveType.EXPLORE:
			return "Explore " + quest.objective_target
		_:
			return ""

func _set_zone(zone: String):
	selected_zone = zone
	selected_quest = null
	selected_card = null
	_update_zone_buttons()
	_rebuild_quest_list()
	_update_detail_panel()

func _update_zone_buttons():
	for zid in zone_buttons:
		var btn: Button = zone_buttons[zid]
		if zid == selected_zone:
			btn.modulate = _zone_color(zid)
		else:
			btn.modulate = Color(1, 1, 1)

func _zone_display_name(zone: String) -> String:
	match zone:
		"forest":        return "Forest"
		"desert":        return "Desert"
		"snow_mountain": return "Snow Mountain"
		_:               return zone.capitalize()

func _zone_color(zone: String) -> Color:
	match zone:
		"forest":        return Color(0.35, 0.85, 0.45)
		"desert":        return Color(0.95, 0.75, 0.25)
		"snow_mountain": return Color(0.55, 0.85, 1.0)
		_:               return Color(1, 1, 1)

func _input(event):
	if visible and event is InputEventKey and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()
