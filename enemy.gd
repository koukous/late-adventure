extends CharacterBody2D
# Simple Enemy - Takes damage and dies when hit
# Works with either Sprite2D or AnimatedSprite2D!

@export var max_health: int = 30
@export var knockback_force: float = 200.0

var current_health: int
var sprite  # Will hold either Sprite2D or AnimatedSprite2D

func _ready():
	current_health = max_health
	
	# Try to find either AnimatedSprite2D or Sprite2D
	if has_node("AnimatedSprite2D"):
		sprite = $AnimatedSprite2D
	elif has_node("Sprite2D"):
		sprite = $Sprite2D
	else:
		print("Warning: Enemy has no sprite!")
	
	# Connect to the player's attack area
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var attack_area = player.get_node("AttackArea")
		attack_area.body_entered.connect(_on_hit_by_attack)

func _on_hit_by_attack(body):
	# Check if the body that got hit is THIS enemy
	if body == self:
		take_damage(10)

func take_damage(amount: int):
	current_health -= amount
	print("Enemy took ", amount, " damage! Health: ", current_health)
	
	# Visual feedback - flash red
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3)  # Red flash
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)  # Back to normal
	
	# Check if dead
	if current_health <= 0:
		die()

func die():
	print("Enemy died!")
	# Optional: play death animation, drop items, etc.
	queue_free()  # Remove from scene
