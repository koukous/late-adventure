extends Area2D
# Health Pickup - heals player when collected

@export var heal_amount: int = 25  # How much health to restore

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	# Connect the signal for when player enters the area
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if it's the player
	if body.is_in_group("player"):
		# Heal the player
		if body.has_method("heal"):
			body.heal(heal_amount)
			print("Player healed for ", heal_amount, "!")
			
			# Play pickup animation/effect (optional)
			pickup_effect()
			
			# Remove the pickup
			queue_free()

func pickup_effect():
	# Optional visual effect when picked up
	# Make it grow and fade out quickly
	var tween = create_tween()
	tween.set_parallel(true)  # Run animations at same time
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)  # Fade out
