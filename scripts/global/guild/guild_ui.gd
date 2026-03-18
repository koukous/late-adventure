extends Control
# Guild UI - shows current rank and progress to next rank

var guild_manager

# UI elements
var main_panel: Panel
var title_label: Label
var current_rank_label: Label
var progress_container: VBoxContainer
var rank_up_button: Button

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	z_index = 100
	
	guild_manager = get_node_or_null("/root/GuildManager")
	
	if guild_manager:
		# Connect to signals
		guild_manager.rank_changed.connect(_on_rank_changed)
		guild_manager.rank_up_available.connect(_on_rank_up_available)
		guild_manager.quest_completed.connect(_on_quest_completed)
	
	create_ui()
	update_display()
	
	print("✅ Guild UI ready")

func create_ui():
	# Main panel
	main_panel = Panel.new()
	main_panel.size = Vector2(500, 600)
	main_panel.position = Vector2(400, 50)
	main_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_panel)
	
	# Title
	title_label = Label.new()
	title_label.text = "GUILD STATUS"
	title_label.position = Vector2(170, 20)
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(title_label)
	
	# Current rank display
	current_rank_label = Label.new()
	current_rank_label.position = Vector2(30, 80)
	current_rank_label.size = Vector2(440, 100)
	current_rank_label.add_theme_font_size_override("font_size", 20)
	current_rank_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	current_rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(current_rank_label)
	
	# Progress section
	var progress_title = Label.new()
	progress_title.text = "Progress to Next Rank:"
	progress_title.position = Vector2(30, 200)
	progress_title.add_theme_font_size_override("font_size", 18)
	progress_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(progress_title)
	
	progress_container = VBoxContainer.new()
	progress_container.position = Vector2(30, 240)
	progress_container.size = Vector2(440, 250)
	progress_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_panel.add_child(progress_container)
	
	# Rank up button
	rank_up_button = Button.new()
	rank_up_button.text = "RANK UP!"
	rank_up_button.position = Vector2(150, 520)
	rank_up_button.size = Vector2(200, 50)
	rank_up_button.add_theme_font_size_override("font_size", 20)
	rank_up_button.pressed.connect(_on_rank_up_pressed)
	main_panel.add_child(rank_up_button)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(400, 20)
	close_button.size = Vector2(80, 30)
	close_button.pressed.connect(_on_close_pressed)
	main_panel.add_child(close_button)

func update_display():
	if not guild_manager:
		return
	
	# Get current rank info
	var current_rank_name = guild_manager.get_rank_name(guild_manager.current_rank)
	var player_level = 1  # TODO: Get from player
	var next_rank_reqs = guild_manager.get_next_rank_requirements(player_level)
	
	# Update current rank
	current_rank_label.text = "Current Rank: " + current_rank_name + "\n"
	current_rank_label.text += "Quests Completed: " + str(guild_manager.quests_completed)
	
	# Clear progress container
	for child in progress_container.get_children():
		child.queue_free()
	
	# Check if max rank
	if guild_manager.current_rank == guild_manager.Rank.S:
		var max_label = Label.new()
		max_label.text = "🏆 Maximum Rank Achieved! 🏆\n\nYou are a legendary S-Rank adventurer!"
		max_label.add_theme_font_size_override("font_size", 16)
		max_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		progress_container.add_child(max_label)
		
		rank_up_button.disabled = true
		rank_up_button.text = "MAX RANK"
	else:
		# Show requirements
		var next_label = Label.new()
		next_label.text = "Next Rank: " + next_rank_reqs["rank"]
		next_label.add_theme_font_size_override("font_size", 18)
		progress_container.add_child(next_label)
		
		# Quest requirement
		var quest_label = Label.new()
		var quests_met = guild_manager.quests_completed >= next_rank_reqs["quests_needed"]
		var quest_check = "✓" if quests_met else "✗"
		quest_label.text = quest_check + " Quests: " + str(next_rank_reqs["quests_current"]) + "/" + str(next_rank_reqs["quests_needed"])
		if quests_met:
			quest_label.add_theme_color_override("font_color", Color(0, 1, 0))
		else:
			quest_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		progress_container.add_child(quest_label)
		
		# Level requirement
		var level_label = Label.new()
		var level_met = player_level >= next_rank_reqs["level_needed"]
		var level_check = "✓" if level_met else "✗"
		level_label.text = level_check + " Level: " + str(next_rank_reqs["level_current"]) + "/" + str(next_rank_reqs["level_needed"])
		if level_met:
			level_label.add_theme_color_override("font_color", Color(0, 1, 0))
		else:
			level_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
		progress_container.add_child(level_label)
		
		# Trial boss
		var trial_label = Label.new()
		trial_label.text = "Trial Boss: " + next_rank_reqs["trial_boss"]
		trial_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
		progress_container.add_child(trial_label)
		
		# Update rank up button
		var can_rank_up = next_rank_reqs["can_rank_up"]
		rank_up_button.disabled = not can_rank_up
		if can_rank_up:
			rank_up_button.text = "RANK UP!"
			rank_up_button.modulate = Color(0.7, 1, 0.7)
		else:
			rank_up_button.text = "Requirements Not Met"
			rank_up_button.modulate = Color(1, 1, 1)

func _on_rank_changed(new_rank):
	print("Rank changed to: ", guild_manager.get_rank_name(new_rank))
	update_display()
	show_rank_up_celebration()

func _on_quest_completed():
	print("Quest completed!")
	update_display()

func _on_rank_up_available(next_rank):
	print("⭐ Rank up is now available to rank ", guild_manager.get_rank_letter(next_rank))
	update_display()

func _on_rank_up_pressed():
	if guild_manager:
		if guild_manager.rank_up():
			print("Ranked up successfully!")
		else:
			print("Cannot rank up yet!")

func _on_close_pressed():
	visible = false

func show_rank_up_celebration():
	# Show celebration message
	var celebration = Label.new()
	celebration.text = "🎉 RANK UP! 🎉"
	celebration.position = Vector2(150, 250)
	celebration.add_theme_font_size_override("font_size", 32)
	celebration.add_theme_color_override("font_color", Color(1, 0.8, 0))
	main_panel.add_child(celebration)
	
	# Remove after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if celebration:
		celebration.queue_free()

func _input(event):
	# Press ESC to close
	if event.is_action_pressed("ui_cancel") and visible:
		visible = false
