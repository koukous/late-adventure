extends CharacterBody2D

# Movement settings
@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Attack settings
@export var attack_cooldown: float = 0.5
@export var base_damage: int = 10

# Health settings
@export var max_health: int = 100
@export var invincibility_duration: float = 1.0

# State tracking
var facing_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var can_attack: bool = true
var attack_timer: float = 0.0
var current_health: int
var is_invincible: bool = false
var invincibility_timer: float = 0.0

# Node references
@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea
@onready var attack_hitbox = $AttackArea/AttackCollision

# Sound effect references
@onready var attack_sound = $AttackSound
@onready var hurt_sound = $HurtSound
@onready var heal_sound = $HealSound

# Signals
signal health_changed(new_health, max_health)
signal player_died

func _ready():
	current_health = max_health
	attack_hitbox.disabled = true
	health_changed.emit(current_health, max_health)
	attack_area.body_entered.connect(_on_attack_body_entered)

func _physics_process(delta):
	update_timers(delta)

	if not is_attacking:
		handle_movement(delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	update_animation()

func update_timers(delta):
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true

	if invincibility_timer > 0:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			animated_sprite.modulate = Color(1, 1, 1)

func handle_movement(delta):
	var input_direction = get_input_direction()

	if input_direction != Vector2.ZERO:
		facing_direction = input_direction

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

func get_attack_damage() -> int:
	var equipment_manager = get_node_or_null("/root/EquipmentManager")
	var bonus = equipment_manager.get_total_damage_bonus() if equipment_manager else 0
	return base_damage + bonus

func start_attack():
	is_attacking = true
	can_attack = false
	attack_timer = attack_cooldown

	if attack_sound:
		attack_sound.play()

	update_attack_hitbox_position()
	attack_hitbox.disabled = false

	# Hit bodies already overlapping (body_entered won't fire for them)
	for body in attack_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(get_attack_damage())

	await get_tree().create_timer(0.2).timeout
	attack_hitbox.disabled = true

	await get_tree().create_timer(0.3).timeout
	is_attacking = false

func _on_attack_body_entered(body):
	if not attack_hitbox.disabled and body.has_method("take_damage"):
		body.take_damage(get_attack_damage())

func update_attack_hitbox_position():
	var offset_distance = 40

	if abs(facing_direction.x) > abs(facing_direction.y):
		if facing_direction.x < 0:
			attack_area.position = Vector2(-offset_distance, 0)
		else:
			attack_area.position = Vector2(offset_distance, 0)
	else:
		if facing_direction.y < 0:
			attack_area.position = Vector2(0, -offset_distance)
		else:
			attack_area.position = Vector2(0, offset_distance)

func take_damage(amount: int):
	if is_invincible:
		return

	current_health -= amount

	if hurt_sound:
		hurt_sound.play()

	health_changed.emit(current_health, max_health)
	animated_sprite.modulate = Color(1, 0.3, 0.3)
	is_invincible = true
	invincibility_timer = invincibility_duration
	blink_while_invincible()

	if current_health <= 0:
		die()

func blink_while_invincible():
	var blink_count = 0
	var max_blinks = int(invincibility_duration / 0.15)

	while is_invincible and blink_count < max_blinks:
		await get_tree().create_timer(0.075).timeout
		if is_invincible:
			animated_sprite.modulate.a = 0.3

		await get_tree().create_timer(0.075).timeout
		if is_invincible:
			animated_sprite.modulate = Color(1, 1, 1)

		blink_count += 1

func heal(amount: int):
	current_health = min(current_health + amount, max_health)

	if heal_sound:
		heal_sound.play()

	health_changed.emit(current_health, max_health)

func die():
	player_died.emit()
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

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

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if get_viewport().gui_get_focus_owner():
			return

		var crafting_ui = get_node_or_null("/root/CraftingUI")
		if crafting_ui and crafting_ui.visible:
			return

		var guild_ui = get_node_or_null("/root/GuildUI")
		if guild_ui and guild_ui.visible:
			return

		var global_ui = get_node_or_null("/root/GlobalUI")
		if global_ui:
			if global_ui.inventory_ui and global_ui.inventory_ui.visible:
				return
			if global_ui.equipment_ui and global_ui.equipment_ui.visible:
				return

		if can_attack and not is_attacking:
			start_attack()
