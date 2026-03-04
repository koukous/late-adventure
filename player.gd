extends CharacterBody2D
# Player with DEBUG PRINTS to see what's happening

# Movement settings
@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Attack settings
@export var attack_cooldown: float = 0.5

# State tracking
var facing_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var can_attack: bool = true
var attack_timer: float = 0.0

# Node references
@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_hitbox = $AttackArea/AttackCollision

func _ready():
	# DEBUG: Print to verify nodes exist
	print("=== PLAYER DEBUG ===")
	print("AttackArea exists: ", attack_area != null)
	print("AttackCollision exists: ", attack_hitbox != null)
	
	# Make sure attack hitbox is disabled at start
	attack_hitbox.disabled = true
	
	# Connect signal to see when attack hits something
	attack_area.body_entered.connect(_on_attack_hit)

func _on_attack_hit(body):
	print("Attack hit something: ", body.name)

func _physics_process(delta):
	# Update attack cooldown timer
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	# Check for attack input
	if Input.is_action_just_pressed("attack"):
		print("Attack button pressed! Can attack: ", can_attack, " Is attacking: ", is_attacking)
		if can_attack and not is_attacking:
			start_attack()
	
	# Only allow movement if not attacking
	if not is_attacking:
		handle_movement(delta)
	else:
		# Slow down during attack
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	update_animation()

func handle_movement(delta):
	var input_direction = get_input_direction()
	
	# Update facing direction when moving
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction
	
	# Apply movement
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func get_input_direction() -> Vector2:
	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	return direction.normalized()

func start_attack():
	print(">>> STARTING ATTACK <<<")
	is_attacking = true
	can_attack = false
	attack_timer = attack_cooldown
	
	# Position the attack hitbox based on facing direction
	update_attack_hitbox_position()
	
	# Enable hitbox briefly
	attack_hitbox.disabled = false
	print("Attack hitbox ENABLED")
	
	# Disable hitbox after a short time (attack duration)
	await get_tree().create_timer(0.2).timeout
	attack_hitbox.disabled = true
	print("Attack hitbox DISABLED")
	
	# Wait for attack animation to finish
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

func update_attack_hitbox_position():
	var offset_distance = 40
	
	if abs(facing_direction.x) > abs(facing_direction.y):
		# Attacking left or right
		if facing_direction.x < 0:
			attack_area.position = Vector2(-offset_distance, 0)
			print("Attack position: LEFT")
		else:
			attack_area.position = Vector2(offset_distance, 0)
			print("Attack position: RIGHT")
	else:
		# Attacking up or down
		if facing_direction.y < 0:
			attack_area.position = Vector2(0, -offset_distance)
			print("Attack position: UP")
		else:
			attack_area.position = Vector2(0, offset_distance)
			print("Attack position: DOWN")

func update_animation():
	var is_moving = velocity.length() > 10
	
	if is_attacking:
		animated_sprite.play("idle")
	elif is_moving:
		if abs(facing_direction.x) > abs(facing_direction.y):
			if facing_direction.x < 0:
				animated_sprite.play("walk_left")
			else:
				animated_sprite.play("walk_right")
		else:
			if facing_direction.y < 0:
				animated_sprite.play("walk_up")
			else:
				animated_sprite.play("walk_down")
	else:
		animated_sprite.play("idle")
