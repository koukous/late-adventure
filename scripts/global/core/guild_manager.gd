extends Node
# Guild Rank Manager - tracks player's guild rank and progression
# Add to Autoload as "GuildManager"

# Guild ranks from lowest to highest
enum Rank {
	F,  # Rookie
	E,  # Novice
	D,  # Apprentice
	C,  # Adventurer
	B,  # Veteran
	A,  # Expert
	S   # Master
}

# Current rank
var current_rank: Rank = Rank.F

# Rank progression tracking
var quests_completed: int = 0
var total_monsters_killed: int = 0
var total_resources_gathered: int = 0
var dungeons_cleared: int = 0

# Rank requirements
var rank_requirements = {
	Rank.E: {
		"quests": 5,
		"level": 3,
		"trial_boss": "Forest Guardian"
	},
	Rank.D: {
		"quests": 15,
		"level": 6,
		"trial_boss": "Cave Troll"
	},
	Rank.C: {
		"quests": 30,
		"level": 10,
		"trial_boss": "Mountain Drake"
	},
	Rank.B: {
		"quests": 50,
		"level": 15,
		"trial_boss": "Shadow Beast"
	},
	Rank.A: {
		"quests": 75,
		"level": 20,
		"trial_boss": "Ancient Golem"
	},
	Rank.S: {
		"quests": 100,
		"level": 25,
		"trial_boss": "Demon Lord"
	}
}

# Signals
signal rank_changed(new_rank: Rank)
signal rank_up_available(next_rank: Rank)
signal quest_completed()

func _ready():
	pass

# Get rank name as string
func get_rank_name(rank: Rank) -> String:
	match rank:
		Rank.F: return "F - Rookie"
		Rank.E: return "E - Novice"
		Rank.D: return "D - Apprentice"
		Rank.C: return "C - Adventurer"
		Rank.B: return "B - Veteran"
		Rank.A: return "A - Expert"
		Rank.S: return "S - Master"
		_: return "Unknown"

# Get short rank name
func get_rank_letter(rank: Rank) -> String:
	match rank:
		Rank.F: return "F"
		Rank.E: return "E"
		Rank.D: return "D"
		Rank.C: return "C"
		Rank.B: return "B"
		Rank.A: return "A"
		Rank.S: return "S"
		_: return "?"

# Check if can rank up
func can_rank_up(player_level: int = 1) -> bool:
	# Already at max rank
	if current_rank == Rank.S:
		return false
	
	var next_rank = current_rank + 1
	
	if not rank_requirements.has(next_rank):
		return false
	
	var reqs = rank_requirements[next_rank]
	
	# Check all requirements
	if quests_completed < reqs["quests"]:
		return false
	
	if player_level < reqs["level"]:
		return false
	
	# All requirements met!
	return true

# Get requirements for next rank
func get_next_rank_requirements(player_level: int = 1) -> Dictionary:
	if current_rank == Rank.S:
		return {"message": "Maximum rank achieved!"}
	
	var next_rank = current_rank + 1
	var reqs = rank_requirements[next_rank]
	
	return {
		"rank": get_rank_name(next_rank),
		"quests_needed": reqs["quests"],
		"quests_current": quests_completed,
		"quests_remaining": max(0, reqs["quests"] - quests_completed),
		"level_needed": reqs["level"],
		"level_current": player_level,
		"trial_boss": reqs["trial_boss"],
		"can_rank_up": can_rank_up(player_level)
	}

# Rank up (call after passing trial boss)
func rank_up() -> bool:
	if current_rank == Rank.S:
		return false

	current_rank += 1
	rank_changed.emit(current_rank)

	# Save immediately after rank up
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		var scene_manager = get_node_or_null("/root/SceneManager")
		var scene_path = scene_manager.current_scene.scene_file_path if scene_manager and scene_manager.current_scene else ""
		var player = get_tree().get_first_node_in_group("player")
		var pos = player.global_position if player else Vector2.ZERO
		save_manager.save_game(scene_path, pos)

	return true

# Track quest completion
func complete_quest():
	quests_completed += 1
	quest_completed.emit()
	check_rank_up_availability()

# Track monster kills
func add_monster_kill():
	total_monsters_killed += 1

# Track resources gathered
func add_resource_gathered():
	total_resources_gathered += 1

# Track dungeon clears
func clear_dungeon():
	dungeons_cleared += 1

# Check if rank up is now available
func check_rank_up_availability(player_level: int = 1):
	if can_rank_up(player_level):
		rank_up_available.emit(current_rank + 1)

# Get current rank info
func get_rank_info() -> Dictionary:
	return {
		"current_rank": current_rank,
		"rank_name": get_rank_name(current_rank),
		"rank_letter": get_rank_letter(current_rank),
		"quests_completed": quests_completed,
		"monsters_killed": total_monsters_killed,
		"resources_gathered": total_resources_gathered,
		"dungeons_cleared": dungeons_cleared
	}

# Save/Load functions (for future save system)
func save_guild_data() -> Dictionary:
	return {
		"rank": current_rank,
		"quests": quests_completed,
		"monsters": total_monsters_killed,
		"resources": total_resources_gathered,
		"dungeons": dungeons_cleared
	}

func load_guild_data(data: Dictionary):
	current_rank = data.get("rank", Rank.F)
	quests_completed = data.get("quests", 0)
	total_monsters_killed = data.get("monsters", 0)
	total_resources_gathered = data.get("resources", 0)
	dungeons_cleared = data.get("dungeons", 0)
