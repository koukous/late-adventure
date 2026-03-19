extends Node
# SaveManager - handles saving, loading, and deleting game state
# Add to Autoload as "SaveManager"

const SAVE_PATH = "user://save.json"

signal save_completed
signal save_loaded
signal save_deleted

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(scene_path: String = "", player_position: Vector2 = Vector2.ZERO):
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	var equipment_manager = get_node_or_null("/root/EquipmentManager")
	var guild_manager = get_node_or_null("/root/GuildManager")

	var data = {
		"scene": scene_path,
		"player_position": { "x": player_position.x, "y": player_position.y },
		"guild": guild_manager.save_guild_data() if guild_manager else {},
		"inventory": _serialize_inventory(inventory_manager),
		"equipment": _serialize_equipment(equipment_manager)
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		save_completed.emit()

func load_game() -> bool:
	if not has_save():
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		return false

	var data = json.get_data()

	var inventory_manager = get_node_or_null("/root/InventoryManager")
	var equipment_manager = get_node_or_null("/root/EquipmentManager")
	var guild_manager = get_node_or_null("/root/GuildManager")

	if guild_manager and data.has("guild"):
		guild_manager.load_guild_data(data["guild"])

	if inventory_manager and data.has("inventory"):
		_deserialize_inventory(inventory_manager, data["inventory"])

	if equipment_manager and data.has("equipment"):
		_deserialize_equipment(equipment_manager, data["equipment"])

	save_loaded.emit()
	return true

func get_saved_scene() -> String:
	if not has_save():
		return ""
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return ""
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return ""
	file.close()
	return json.get_data().get("scene", "")

func get_saved_player_position() -> Vector2:
	if not has_save():
		return Vector2.ZERO
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return Vector2.ZERO
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return Vector2.ZERO
	file.close()
	var pos = json.get_data().get("player_position", {"x": 0, "y": 0})
	return Vector2(pos["x"], pos["y"])

func delete_save():
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		save_deleted.emit()

# --- Serialization ---

func _serialize_inventory(inventory_manager) -> Dictionary:
	if not inventory_manager:
		return {}
	var result = {}
	for item_name in inventory_manager.inventory:
		var entry = inventory_manager.inventory[item_name]
		var item_data = entry["data"]
		if item_data and item_data.resource_path != "":
			result[item_name] = {
				"resource_path": item_data.resource_path,
				"quantity": entry["quantity"]
			}
	return result

func _deserialize_inventory(inventory_manager, data: Dictionary):
	inventory_manager.clear_inventory()
	for item_name in data:
		var entry = data[item_name]
		var item = load(entry["resource_path"])
		if item:
			inventory_manager.add_item(item, entry["quantity"])

func _serialize_equipment(equipment_manager) -> Dictionary:
	if not equipment_manager:
		return {}
	var result = {}
	for slot in equipment_manager.equipped_items:
		var item = equipment_manager.equipped_items[slot]
		result[slot] = item.resource_path if item and item.resource_path != "" else null
	return result

func _deserialize_equipment(equipment_manager, data: Dictionary):
	for slot in data:
		var path = data[slot]
		if path:
			var item = load(path)
			if item:
				equipment_manager.equip_item(item)
