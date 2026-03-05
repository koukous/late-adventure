extends CharacterBody2D
# Enemy with AI, drops, AND sound effects!

@export var max_health: int = 30
@export var contact_damage: int = 10
@export var damage_cooldown: float = 1.0
@export var move_speed: float = 80.0
@export var detection_range: float = 300.0

# Drop settings
@export var drop_health_chance: float = 0.3
@export var drop_coin_chance: float = 0.7
@export var health_pickup_scene: PackedScene
@export var coin_scene: PackedScene

var current_health: int
var sprite
var can_damage_player: bool = true
var damage_timer: float = 0.0
var player = null

# Sound references
@onready var hurt_sound = $HurtSound
@onready var death_sound = $DeathSound

func _ready():
	current_health = max_health
	
	if has_node("AnimatedSprite2D"):
		sprite = $AnimatedSprite2D
	elif has_node("Sprite2D"):
		sprite = $Sprite2D
	
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		var attack_area = player.get_node("AttackArea")
		attack_area.body_entered.connect(_on_hit_by_attack)

func _physics_process(delta):
	if damage_timer > 0:
		damage_timer -= delta
		if damage_timer <= 0:
			can_damage_player = true
	
	if player:
		chase_player()
	
	move_and_slide()
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
	
	# Play hurt sound!
	if hurt_sound:
		hurt_sound.play()
	
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
	
	# Play death sound!
	if death_sound:
		death_sound.play()
		# Wait for death sound to finish before removing enemy
		await death_sound.finished
	
	drop_items()
	queue_free()

func drop_items():
	if randf() < drop_health_chance and health_pickup_scene:
		var health_pickup = health_pickup_scene.instantiate()
		health_pickup.global_position = global_position
		get_parent().add_child(health_pickup)
		print("Dropped health pickup!")
	
	if randf() < drop_coin_chance and coin_scene:
		var coin = coin_scene.instantiate()
		coin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(coin)
		print("Dropped coin!")
