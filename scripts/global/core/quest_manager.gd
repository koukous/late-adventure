extends Node
# Quest Manager - tracks available quests, active quest, and completion
# Add to Autoload as "QuestManager"

signal quest_accepted(quest: QuestData)
signal quest_abandoned(quest: QuestData)
signal quest_progress_updated(current: int, total: int)
signal quest_ready_to_complete(quest: QuestData)

var available_quests: Array[QuestData] = []
var active_quest: QuestData = null
var active_progress: int = 0
var completed_quest_ids: Array[String] = []

func _ready():
	_register_quests()

# ---- Quest registry ----

func _register_quests():
	# --- F Rank (Forest) ---
	available_quests.append(_quest("f_rats",    "Rat Extermination",
		"The storage room is overrun with rats. The innkeeper will pay well to have them cleared out.",
		0, QuestData.ObjectiveType.KILL, "Rat", 5, 50, 100, "forest"))

	available_quests.append(_quest("f_slimes",  "Slime Removal",
		"Slimes are damaging the roads east of town. Eliminate 8 of them.",
		0, QuestData.ObjectiveType.KILL, "Slime", 8, 70, 130, "forest"))

	available_quests.append(_quest("f_wolves",  "Wolf Hunt",
		"Wolves are threatening the farmers near the forest edge. Kill 3 wolves.",
		0, QuestData.ObjectiveType.KILL, "Wolf", 3, 80, 150, "forest"))

	available_quests.append(_quest("f_goblins", "Goblin Patrol",
		"Goblins are raiding the trade road. Drive off their patrol by killing 5 goblins.",
		0, QuestData.ObjectiveType.KILL, "Goblin", 5, 100, 200, "forest"))

	available_quests.append(_quest("f_herbs",   "Herb Gathering",
		"The town healer is running low on medicine. Collect 10 healing herbs.",
		0, QuestData.ObjectiveType.COLLECT, "Herb", 10, 60, 120, "forest"))

	# F -> E trial (Forest)
	available_quests.append(_trial("trial_f_e", "Trial: Forest Guardian",
		"To advance to E-Rank you must prove your strength. Slay the Forest Guardian that lurks in the deep woods.",
		0, "Forest Guardian", "forest"))

	# --- E Rank (Forest) ---
	available_quests.append(_quest("e_bandits",  "Bandit Raid",
		"Forest bandits are ambushing travelers on the east road. Defeat 8 of them.",
		1, QuestData.ObjectiveType.KILL, "Forest Bandit", 8, 150, 300, "forest"))

	available_quests.append(_quest("e_spiders",  "Spider Nest",
		"A giant spider nest is threatening the eastern settlements. Kill 10 giant spiders.",
		1, QuestData.ObjectiveType.KILL, "Giant Spider", 10, 160, 320, "forest"))

	available_quests.append(_quest("e_bats",     "Cave Clearing",
		"Strange bats are emerging from the cave at night and attacking the village. Kill 6 cave bats.",
		1, QuestData.ObjectiveType.KILL, "Cave Bat", 6, 140, 280, "forest"))

	available_quests.append(_quest("e_mushrooms","Rare Mushrooms",
		"The alchemist needs rare cave mushrooms for a new potion. Collect 5 of them.",
		1, QuestData.ObjectiveType.COLLECT, "Cave Mushroom", 5, 120, 250, "forest"))

	available_quests.append(_quest("e_skeletons","Graveyard Watch",
		"Skeletons are rising from the old cemetery at night. Put 8 of them to rest.",
		1, QuestData.ObjectiveType.KILL, "Skeleton", 8, 170, 340, "forest"))

	# E -> D trial (Forest)
	available_quests.append(_trial("trial_e_d", "Trial: Cave Troll",
		"To advance to D-Rank you must defeat the Cave Troll that has claimed the mine tunnels.",
		1, "Cave Troll", "forest"))

	# --- D Rank (Desert) ---
	available_quests.append(_quest("d_scorpions", "Scorpion Swarm",
		"Giant scorpions are terrorizing the desert traders. Kill 10 of them.",
		2, QuestData.ObjectiveType.KILL, "Sand Scorpion", 10, 250, 500, "desert"))

	available_quests.append(_quest("d_sandgolems","Sand Golem Threat",
		"Ancient sand golems have awakened near the ruins. Destroy 6 of them.",
		2, QuestData.ObjectiveType.KILL, "Sand Golem", 6, 270, 540, "desert"))

	available_quests.append(_quest("d_bandits",  "Desert Raiders",
		"Desert raiders are looting caravans along the trade road. Eliminate 8 of them.",
		2, QuestData.ObjectiveType.KILL, "Desert Raider", 8, 260, 520, "desert"))

	available_quests.append(_quest("d_cactus",   "Cactus Fiber",
		"The crafters need rare cactus fiber from the deep desert. Collect 8 bundles.",
		2, QuestData.ObjectiveType.COLLECT, "Cactus Fiber", 8, 200, 400, "desert"))

	# D -> C trial (Desert)
	available_quests.append(_trial("trial_d_c", "Trial: Sand Wyrm",
		"To advance to C-Rank you must slay the Sand Wyrm that terrorizes the desert depths.",
		2, "Sand Wyrm", "desert"))

	# --- C Rank (Snow Mountain) ---
	available_quests.append(_quest("c_frostwolves", "Frost Wolf Pack",
		"A pack of frost wolves has been attacking the mountain settlements. Kill 8 of them.",
		3, QuestData.ObjectiveType.KILL, "Frost Wolf", 8, 400, 800, "snow_mountain"))

	available_quests.append(_quest("c_yetis",    "Yeti Menace",
		"Yetis are blocking the mountain pass and killing travelers. Slay 5 of them.",
		3, QuestData.ObjectiveType.KILL, "Yeti", 5, 420, 840, "snow_mountain"))

	available_quests.append(_quest("c_icespirits","Ice Spirit Hunt",
		"Ice spirits are freezing the village water supply. Dispel 6 of them.",
		3, QuestData.ObjectiveType.KILL, "Ice Spirit", 6, 410, 820, "snow_mountain"))

	available_quests.append(_quest("c_crystals","Frost Crystal Harvest",
		"The mages need frost crystals from the mountain peaks. Collect 6 of them.",
		3, QuestData.ObjectiveType.COLLECT, "Frost Crystal", 6, 380, 760, "snow_mountain"))

	# C -> B trial (Snow Mountain)
	available_quests.append(_trial("trial_c_b", "Trial: Glacier Drake",
		"To advance to B-Rank you must face the Glacier Drake that rules the frozen peaks.",
		3, "Glacier Drake", "snow_mountain"))

# ---- Factory helpers ----

func _quest(id: String, name: String, desc: String, rank: int,
			obj: QuestData.ObjectiveType, target: String,
			count: int, gold: int, xp: int, zone: String = "") -> QuestData:
	var q = QuestData.new()
	q.quest_id        = id
	q.quest_name      = name
	q.description     = desc
	q.rank_required   = rank
	q.objective_type  = obj
	q.objective_target = target
	q.objective_count  = count
	q.reward_gold     = gold
	q.reward_xp       = xp
	q.is_trial        = false
	q.zone            = zone
	return q

func _trial(id: String, name: String, desc: String, rank: int, boss: String, zone: String = "") -> QuestData:
	var q = QuestData.new()
	q.quest_id        = id
	q.quest_name      = name
	q.description     = desc
	q.rank_required   = rank
	q.objective_type  = QuestData.ObjectiveType.TRIAL
	q.objective_target = boss
	q.objective_count  = 1
	q.reward_gold     = 0
	q.reward_xp       = 0
	q.is_trial        = true
	q.zone            = zone
	return q

# ---- Queries ----

# Returns non-trial quests available for the given zone and rank (not yet completed)
func get_quests_for_zone(zone: String, rank: int) -> Array[QuestData]:
	var result: Array[QuestData] = []
	for q in available_quests:
		if q.zone == zone and q.rank_required == rank and not q.is_trial and not completed_quest_ids.has(q.quest_id):
			result.append(q)
	return result

# Returns non-trial quests available for the given rank (not yet completed)
func get_quests_for_rank(rank: int) -> Array[QuestData]:
	var result: Array[QuestData] = []
	for q in available_quests:
		if q.rank_required == rank and not q.is_trial and not completed_quest_ids.has(q.quest_id):
			result.append(q)
	return result

# Returns the trial quest for a given rank (nil if none or already done)
func get_trial_quest_for_rank(rank: int) -> QuestData:
	for q in available_quests:
		if q.rank_required == rank and q.is_trial and not completed_quest_ids.has(q.quest_id):
			return q
	return null

func is_active_quest_complete() -> bool:
	if not active_quest:
		return false
	return active_progress >= active_quest.objective_count

# ---- Accept / Abandon ----

func accept_quest(quest: QuestData) -> bool:
	if active_quest:
		return false  # one quest at a time
	if completed_quest_ids.has(quest.quest_id):
		return false
	active_quest = quest
	active_progress = 0
	quest_accepted.emit(quest)
	return true

func abandon_quest():
	if not active_quest:
		return
	var q = active_quest
	active_quest = null
	active_progress = 0
	quest_abandoned.emit(q)

# ---- Progress tracking ----

func report_kill(monster_name: String):
	if not active_quest:
		return
	if active_quest.objective_type != QuestData.ObjectiveType.KILL:
		return
	if active_quest.objective_target.to_lower() != monster_name.to_lower():
		return
	_advance_progress()

func report_collect(item_name: String):
	if not active_quest:
		return
	if active_quest.objective_type != QuestData.ObjectiveType.COLLECT:
		return
	if active_quest.objective_target.to_lower() != item_name.to_lower():
		return
	_advance_progress()

func report_boss_killed(boss_name: String):
	if not active_quest:
		return
	if active_quest.objective_type != QuestData.ObjectiveType.TRIAL:
		return
	if active_quest.objective_target.to_lower() != boss_name.to_lower():
		return
	active_progress = 1
	quest_progress_updated.emit(1, 1)
	quest_ready_to_complete.emit(active_quest)

func _advance_progress():
	active_progress = min(active_progress + 1, active_quest.objective_count)
	quest_progress_updated.emit(active_progress, active_quest.objective_count)
	if active_progress >= active_quest.objective_count:
		quest_ready_to_complete.emit(active_quest)

# ---- Completion (called by Guild Master) ----

# Marks the active quest complete, gives rewards, notifies GuildManager.
# Returns false if quest is not done yet.
func complete_active_quest() -> bool:
	if not active_quest or not is_active_quest_complete():
		return false

	var quest = active_quest
	completed_quest_ids.append(quest.quest_id)
	active_quest = null
	active_progress = 0

	var guild_manager = get_node_or_null("/root/GuildManager")
	if guild_manager:
		if quest.is_trial:
			guild_manager.rank_up()
		else:
			guild_manager.complete_quest()

	# Gold reward — hook into wallet/economy system when it exists
	# if quest.reward_gold > 0: ...

	return true

# ---- Save / Load ----

func save_quest_data() -> Dictionary:
	return {
		"completed_ids":   completed_quest_ids.duplicate(),
		"active_quest_id": active_quest.quest_id if active_quest else "",
		"active_progress": active_progress,
	}

func load_quest_data(data: Dictionary):
	completed_quest_ids = data.get("completed_ids", [])
	active_progress     = data.get("active_progress", 0)
	var active_id       = data.get("active_quest_id", "")
	active_quest = null
	if active_id != "":
		for q in available_quests:
			if q.quest_id == active_id:
				active_quest = q
				break
