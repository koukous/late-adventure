extends Node
# Global Scene Manager - handles scene transitions
# Add to Autoload as "SceneManager"

var current_scene = null
var previous_scene = null
var player_position = Vector2.ZERO

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func change_scene(scene_path: String, spawn_position: Vector2 = Vector2.ZERO):
	# Store current scene info
	previous_scene = current_scene.scene_file_path if current_scene else ""
	
	# Defer the scene change
	call_deferred("_deferred_change_scene", scene_path, spawn_position)

func _deferred_change_scene(scene_path: String, spawn_position: Vector2):
	# Free current scene
	if current_scene:
		current_scene.free()
	
	# Load new scene
	var new_scene = load(scene_path)
	if new_scene:
		current_scene = new_scene.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		
		# Position player at spawn point
		await get_tree().process_frame
		position_player(spawn_position)
		
		print("Changed to scene: ", scene_path)
	else:
		print("ERROR: Could not load scene: ", scene_path)

func position_player(spawn_pos: Vector2):
	# Find player in new scene
	var player = get_tree().get_first_node_in_group("player")
	if player and spawn_pos != Vector2.ZERO:
		player.global_position = spawn_pos
		print("Player positioned at: ", spawn_pos)

func return_to_previous_scene(spawn_position: Vector2 = Vector2.ZERO):
	if previous_scene != "":
		change_scene(previous_scene, spawn_position)
	else:
		print("No previous scene to return to")
