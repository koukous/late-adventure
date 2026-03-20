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
	# --- F Rank ---
	available_quests.append(_quest("f_rats",    "Rat Extermination",
		"The storage room is overrun with rats. The innkeeper will pay well to have them cleared out.",
		0, QuestData.ObjectiveType.KILL, "Rat", 5, 50, 100))

	available_quests.append(_quest("f_slimes",  "Slime Removal",
		"Slimes are damaging the roads east of town. Eliminate 8 of them.",
		0, QuestData.ObjectiveType.KILL, "Slime", 8, 70, 130))

	available_quests.append(_quest("f_wolves",  "Wolf Hunt",
		"Wolves are threatening the farmers near the forest edge. Kill 3 wolves.",
		0, QuestData.ObjectiveType.KILL, "Wolf", 3, 80, 150))

	available_quests.append(_quest("f_goblins", "Goblin Patrol",
		"Goblins are raiding the trade road. Drive off their patrol by killing 5 goblins.",
		0, QuestData.ObjectiveType.KILL, "Goblin", 5, 100, 200))

	available_quests.append(_quest("f_herbs",   "Herb Gathering",
		"The town healer is running low on medicine. Collect 10 healing herbs.",
		0, QuestData.ObjectiveType.COLLECT, "Herb", 10, 60, 120))

	# F -> E trial
	available_quests.append(_trial("trial_f_e", "Trial: Forest Guardian",
		"To advance to E-Rank you must prove your strength. Slay the Forest Guardian that lurks in the deep woods.",
		0, "Forest Guardian"))

	# --- E Rank ---
	available_quests.append(_quest("e_bandits",  "Bandit Raid",
		"Forest bandits are ambushing travelers on the east road. Defeat 8 of them.",
		1, QuestData.ObjectiveType.KILL, "Forest Bandit", 8, 150, 300))

	available_quests.append(_quest("e_spiders",  "Spider Nest",
		"A giant spider nest is threatening the eastern settlements. Kill 10 giant spiders.",
		1, QuestData.ObjectiveType.KILL, "Giant Spider", 10, 160, 320))

	available_quests.append(_quest("e_bats",     "Cave Clearing",
		"Strange bats are emerging from the cave at night and attacking the village. Kill 6 cave bats.",
		1, QuestData.ObjectiveType.KILL, "Cave Bat", 6, 140, 280))

	available_quests.append(_quest("e_mushrooms","Rare Mushrooms",
		"The alchemist needs rare cave mushrooms for a new potion. Collect 5 of them.",
		1, QuestData.ObjectiveType.COLLECT, "Cave Mushroom", 5, 120, 250))

	available_quests.append(_quest("e_skeletons","Graveyard Watch",
		"Skeletons are rising from the old cemetery at night. Put 8 of them to rest.",
		1, QuestData.ObjectiveType.KILL, "Skeleton", 8, 170, 340))

	# E -> D trial
	available_quests.append(_trial("trial_e_d", "Trial: Cave Troll",
		"To advance to D-Rank you must defeat the Cave Troll that has claimed the mine tunnels.",
		1, "Cave Troll"))

	# --- D Rank ---
	available_quests.append(_quest("d_orcs",    "Orc Warband",
		"An orc warband is blocking the mountain pass. Kill 10 orcs to clear the route.",
		2, QuestData.ObjectiveType.KILL, "Orc", 10, 250, 500))

	available_quests.append(_quest("d_undead",  "Undead Outbreak",
		"The old battlefield is stirring. Destroy 12 undead warriors before they reach the city.",
		2, QuestData.ObjectiveType.KILL, "Undead", 12, 280, 560))

	available_quests.append(_quest("d_ore",     "Iron Ore Collection",
		"The blacksmith urgently needs iron ore. Collect 8 iron ore from the mountain mines.",
		2, QuestData.ObjectiveType.COLLECT, "Iron Ore", 8, 200, 400))

	available_quests.append(_quest("d_harpies", "Harpy Menace",
		"Harpies are attacking mountain travelers. Hunt down 6 of them.",
		2, QuestData.ObjectiveType.KILL, "Harpy", 6, 260, 520))

	# D -> C trial
	available_quests.append(_trial("trial_d_c", "Trial: Mountain Drake",
		"To advance to C-Rank you must slay the Mountain Drake that terrorizes the high passes.",
		2, "Mountain Drake"))

	# --- C Rank ---
	available_quests.append(_quest("c_demons",  "Demon Scouts",
		"Demon scouts have been spotted near the ruins. Eliminate 8 of them before they report back.",
		3, QuestData.ObjectiveType.KILL, "Demon Scout", 8, 400, 800))

	available_quests.append(_quest("c_golems",  "Rogue Golems",
		"Ancient golems in the ruins have gone berserk. Destroy 5 of them.",
		3, QuestData.ObjectiveType.KILL, "Stone Golem", 5, 420, 840))

	available_quests.append(_quest("c_crystals","Crystal Harvest",
		"The mages need mana crystals from the ruins. Collect 6 mana crystals.",
		3, QuestData.ObjectiveType.COLLECT, "Mana Crystal", 6, 380, 760))

	# C -> B trial
	available_quests.append(_trial("trial_c_b", "Trial: Shadow Beast",
		"To advance to B-Rank you must face the Shadow Beast that haunts the cursed ruins.",
		3, "Shadow Beast"))

# ---- Factory helpers ----

func _quest(id: String, name: String, desc: String, rank: int,
			obj: QuestData.ObjectiveType, target: String,
			count: int, gold: int, xp: int) -> QuestData:
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
	return q

func _trial(id: String, name: String, desc: String, rank: int, boss: String) -> QuestData:
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
	return q

# ---- Queries ----

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
