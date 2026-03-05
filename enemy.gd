extends CharacterBody2D
# Enemy that CHASES the player and damages on contact

@export var max_health: int = 30
@export var contact_damage: int = 10
@export var damage_cooldown: float = 1.0
@export var move_speed: float = 80.0  # Chase speed
@export var detection_range: float = 300.0  # How far enemy can "see" player

var current_health: int
var sprite
var can_damage_player: bool = true
var damage_timer: float = 0.0
var player = null

func _ready():
	current_health = max_health
	
	# Find sprite
	if has_node("AnimatedSprite2D"):
		sprite = $AnimatedSprite2D
	elif has_node("Sprite2D"):
		sprite = $Sprite2D
	
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	
	# Connect to player's attack area
	if player:
		var attack_area = player.get_node("AttackArea")
		attack_area.body_entered.connect(_on_hit_by_attack)

func _physics_process(delta):
	# Update damage cooldown
	if damage_timer > 0:
		damage_timer -= delta
		if damage_timer <= 0:
			can_damage_player = true
	
	# Chase the player if they exist and are in range
	if player:
		chase_player()
	
	# Move the enemy
	move_and_slide()
	
	# Check if we're colliding with the player
	check_player_collision()

func chase_player():
	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Only chase if player is within detection range
	if distance_to_player < detection_range:
		# Calculate direction to player
		var direction = (player.global_position - global_position).normalized()
		
		# Move towards player
		velocity = direction * move_speed
	else:
		# Player too far away - stop moving
		velocity = Vector2.ZERO

func check_player_collision():
	# Check all collisions this frame
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# If we hit the player
		if collider and collider.is_in_group("player") and can_damage_player:
			damage_player(collider)

func damage_player(player_node):
	# Tell the player to take damage
	if player_node.has_method("take_damage"):
		player_node.take_damage(contact_damage)
		can_damage_player = false
		damage_timer = damage_cooldown
		print("Enemy damaged player for ", contact_damage, " damage!")

func _on_hit_by_attack(body):
	if body == self:
		take_damage(10)

func take_damage(amount: int):
	current_health -= amount
	print("Enemy took ", amount, " damage! Health: ", current_health)
	
	# Visual feedback
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)
		await get_tree().create_timer(0.1).timeout
		if sprite:  # Check if still exists
			sprite.modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()

func die():
	print("Enemy died!")
	queue_free()
