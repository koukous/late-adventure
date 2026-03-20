extends Resource
class_name QuestData

enum ObjectiveType {
	KILL,
	COLLECT,
	EXPLORE,
	TRIAL  # rank-up boss fight
}

@export var quest_id: String = ""
@export var quest_name: String = ""
@export_multiline var description: String = ""

# Minimum rank to see/accept this quest (matches GuildManager.Rank int value)
@export var rank_required: int = 0

@export var objective_type: ObjectiveType = ObjectiveType.KILL
@export var objective_target: String = ""  # monster name, item name, or boss name
@export var objective_count: int = 1

@export var reward_gold: int = 0
@export var reward_xp: int = 0

# If true this is a rank-up trial quest — completing it calls rank_up()
@export var is_trial: bool = false
