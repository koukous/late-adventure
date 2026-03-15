extends CharacterBody2D
# Player with movement, animations, combat, health, AND sound effects!

# Movement settings
@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Attack settings
@export var attack_cooldown: float = 0.5

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
	
	# Get equipment manager
	var equipment_manager = get_node_or_null("/root/EquipmentManager")
	if equipment_manager:
		equipment_manager.stats_updated.connect(_on_equipment_stats_updated)
		
	# TEST: Add equipment items
	await get_tree().create_timer(1.0).timeout  # Wait for managers to load
	
	var inventory = get_node("/root/InventoryManager")
	if inventory:
		var sword = load("res://resources/equipement/iron_sword.tres")
		var helmet = load("res://resources/equipement/leather_helmet.tres")
		#var chest = load("res://leather_chest.tres")
		
		inventory.add_item(sword, 1)
		inventory.add_item(helmet, 1)
		#inventory.add_item(chest, 1)
		
		print("Test equipment added to inventory!")
		
			# Wait a moment for autoloads to load
	await get_tree().create_timer(0.5).timeout
	
	# Test if EquipmentManager exists
	var eq = get_node_or_null("/root/EquipmentManager")
	if eq:
		print("✅ EquipmentManager FOUND!")
	else:
		print("❌ EquipmentManager NOT FOUND!")
	
	# List all autoloads
	print("=== All Root Nodes ===")
	for child in get_tree().root.get_children():
		print("  - ", child.name)
		
	await get_tree().create_timer(2.0).timeout
	
	# Test equipping directly
	var eq_manager = get_node("/root/EquipmentManager")
	var sword = load("res://resources/craftingRecipe/Iron_Sword_Recepi.tres")
	
	if eq_manager and sword:
		print("=== DIRECT EQUIP TEST ===")
		print("Sword type: ", sword.get_class())
		print("Is EquipmentData: ", sword is EquipmentData)
		
		if sword is EquipmentData:
			eq_manager.equip_item(sword)
			print("Total damage after equip: ", eq_manager.total_damage)
			print("Total strength after equip: ", eq_manager.total_strength)
			
	if inventory:
		# Add crafting materials
		var skin = load("res://resources/monster_skin.tres")
		var bones = load("res://resources/bones.tres")
		var flower = load("res://resources/flower.tres")
		var wood = load("res://resources/wood.tres")
		
		if skin:
			inventory.add_item(skin, 10)
		if bones:
			inventory.add_item(bones, 10)
		if flower:
			inventory.add_item(flower, 10)
		if wood:
			inventory.add_item(wood, 10)
		
		print("Test materials added!")

func _physics_process(delta):
	update_timers(delta)
	
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking:
		start_attack()
	
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

func start_attack():
	is_attacking = true
	can_attack = false
	attack_timer = attack_cooldown
	
	# Play attack sound!
	if attack_sound:
		attack_sound.play()
	
	update_attack_hitbox_position()
	attack_hitbox.disabled = false
	
	await get_tree().create_timer(0.2).timeout
	attack_hitbox.disabled = true
	
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

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
	print("Player took ", amount, " damage! Health: ", current_health, "/", max_health)
	
	# Play hurt sound!
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
	print("Player healed ", amount, "! Health: ", current_health, "/", max_health)
	
	# Play heal sound!
	if heal_sound:
		heal_sound.play()
	
	health_changed.emit(current_health, max_health)

func die():
	print("Player died!")
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
		
func _on_equipment_stats_updated():
	# Recalculate damage with equipment bonuses
	update_combat_stats()

func update_combat_stats():
	var equipment_manager = get_node_or_null("/root/EquipmentManager")
	if equipment_manager:
		var base_damage = 10  # Your base damage
		var bonus_damage = equipment_manager.get_total_damage_bonus()
		var total_damage = base_damage + bonus_damage
		
		print("Total damage: ", total_damage, " (Base: ", base_damage, " + Equipment: ", bonus_damage, ")")
		
		# Use this total_damage in your attack code

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Check if mouse is over UI
		var ui_control = get_viewport().gui_get_focus_owner()
		if ui_control:
			return  # Mouse is on UI - don't attack
		
		# Check if any UI is visible
		var crafting_ui = get_node_or_null("/root/CraftingUI")
		if crafting_ui and crafting_ui.visible:
			return  # Crafting UI open - don't attack
		
		start_attack()
