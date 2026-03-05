extends CharacterBody2D
# Enemy that chases player, damages on contact, and DROPS ITEMS when killed

@export var max_health: int = 30
@export var contact_damage: int = 10
@export var damage_cooldown: float = 1.0
@export var move_speed: float = 80.0
@export var detection_range: float = 300.0

# Drop settings
@export var drop_health_chance: float = 0.3  # 30% chance to drop health
@export var drop_coin_chance: float = 0.7    # 70% chance to drop coin
@export var health_pickup_scene: PackedScene  # Drag health pickup scene here
@export var coin_scene: PackedScene           # Drag coin scene here

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
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player < detection_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
	else:
		velocity = Vector2.ZERO

func check_player_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider and collider.is_in_group("player") and can_damage_player:
			damage_player(collider)

func damage_player(player_node):
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
		if sprite:
			sprite.modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()

func die():
	print("Enemy died!")
	
	# Drop items before dying!
	drop_items()
	
	queue_free()

func drop_items():
	# Randomly drop health pickup
	if randf() < drop_health_chance and health_pickup_scene:
		var health_pickup = health_pickup_scene.instantiate()
		health_pickup.global_position = global_position
		get_parent().add_child(health_pickup)
		print("Dropped health pickup!")
	
	# Randomly drop coin
	if randf() < drop_coin_chance and coin_scene:
		var coin = coin_scene.instantiate()
		coin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(coin)
		print("Dropped coin!")
