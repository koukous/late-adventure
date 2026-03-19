extends Control

const VILLAGE_SCENE = "res://scenes/village.tscn"

var save_manager
var confirm_panel: Panel = null

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	save_manager = get_node_or_null("/root/SaveManager")
	create_ui()

func create_ui():
	var screen = get_viewport().get_visible_rect().size
	var center = screen / 2

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "LATE ADVENTURE"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = center.y - 220
	title.offset_bottom = center.y - 140
	add_child(title)

	# Buttons
	var btn_size = Vector2(300, 60)
	var btn_x = center.x - btn_size.x / 2
	var spacing = 80

	_make_button("New Game",    Vector2(btn_x, center.y - 60),            btn_size, false,              _on_new_game_pressed)
	_make_button("Continue",    Vector2(btn_x, center.y - 60 + spacing),  btn_size, not _has_save(),    _on_continue_pressed)
	_make_button("Delete Save", Vector2(btn_x, center.y - 60 + spacing*2), btn_size, not _has_save(),   _on_delete_save_pressed)

func _make_button(label: String, pos: Vector2, sz: Vector2, disabled: bool, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.position = pos
	btn.size = sz
	btn.custom_minimum_size = sz
	btn.add_theme_font_size_override("font_size", 22)
	btn.disabled = disabled
	btn.pressed.connect(callback)
	add_child(btn)
	return btn

func _has_save() -> bool:
	return save_manager != null and save_manager.has_save()

# --- Button handlers ---

func _on_new_game_pressed():
	_reset_all_managers()
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.change_scene(VILLAGE_SCENE)

func _on_continue_pressed():
	if not _has_save():
		return

	var saved_scene = save_manager.get_saved_scene()
	var saved_position = save_manager.get_saved_player_position()

	save_manager.load_game()

	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		var target = saved_scene if saved_scene != "" else VILLAGE_SCENE
		scene_manager.change_scene(target, saved_position)

func _on_delete_save_pressed():
	_show_confirm_dialog()

# --- Confirm dialog ---

func _show_confirm_dialog():
	if confirm_panel:
		return

	var center = get_viewport().get_visible_rect().size / 2

	confirm_panel = Panel.new()
	confirm_panel.size = Vector2(420, 170)
	confirm_panel.position = center - confirm_panel.size / 2
	add_child(confirm_panel)

	var label = Label.new()
	label.text = "Delete save? This cannot be undone."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(10, 35)
	label.size = Vector2(400, 40)
	label.add_theme_font_size_override("font_size", 16)
	confirm_panel.add_child(label)

	var yes_btn = Button.new()
	yes_btn.text = "Yes, Delete"
	yes_btn.position = Vector2(40, 105)
	yes_btn.size = Vector2(150, 42)
	yes_btn.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	yes_btn.pressed.connect(_on_confirm_delete)
	confirm_panel.add_child(yes_btn)

	var no_btn = Button.new()
	no_btn.text = "Cancel"
	no_btn.position = Vector2(230, 105)
	no_btn.size = Vector2(150, 42)
	no_btn.pressed.connect(_on_cancel_delete)
	confirm_panel.add_child(no_btn)

func _on_confirm_delete():
	if save_manager:
		save_manager.delete_save()
	_close_confirm_dialog()
	# Rebuild to grey out Continue / Delete buttons
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	create_ui()

func _on_cancel_delete():
	_close_confirm_dialog()

func _close_confirm_dialog():
	if confirm_panel:
		confirm_panel.queue_free()
		confirm_panel = null

# --- Helpers ---

func _reset_all_managers():
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if inventory_manager:
		inventory_manager.clear_inventory()

	var equipment_manager = get_node_or_null("/root/EquipmentManager")
	if equipment_manager:
		for slot in equipment_manager.equipped_items.keys():
			equipment_manager.equipped_items[slot] = null
		equipment_manager.calculate_total_stats()

	var guild_manager = get_node_or_null("/root/GuildManager")
	if guild_manager:
		guild_manager.load_guild_data({})
