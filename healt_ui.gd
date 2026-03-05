extends CanvasLayer
# Health Bar UI - displays player's current health

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthLabel

func _ready():
	# Find the player and connect to their health signal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
		
		# Set initial health display
		_on_player_health_changed(player.current_health, player.max_health)

func _on_player_health_changed(current_health, max_health):
	# Update the health bar
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Update the label text
	health_label.text = str(current_health) + " / " + str(max_health)
	
	# Change color based on health percentage
	var health_percent = float(current_health) / float(max_health)
	if health_percent > 0.6:
		health_bar.modulate = Color(0.2, 1, 0.2)  # Green
	elif health_percent > 0.3:
		health_bar.modulate = Color(1, 1, 0.2)  # Yellow
	else:
		health_bar.modulate = Color(1, 0.2, 0.2)  # Red

func _on_player_died():
	health_label.text = "DEAD"
