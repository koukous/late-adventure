extends Area2D
# Health Pickup with sound effect

@export var heal_amount: int = 25

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var pickup_sound = $PickupSound

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(heal_amount)
			print("Player healed for ", heal_amount, "!")
			
			# Play sound!
			if pickup_sound:
				pickup_sound.play()
			
			pickup_effect()
			
			# Wait for sound to finish
			if pickup_sound:
				await pickup_sound.finished
			
			queue_free()

func pickup_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
