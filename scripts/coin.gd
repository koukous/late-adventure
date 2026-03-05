extends Area2D
# Coin - collectible for scoring

@export var coin_value: int = 1  # How many points this coin is worth

@onready var sprite = $Sprite2D

# Signal to notify when coin is collected (for score tracking)
signal coin_collected(value)

func _ready():
	# Connect the signal for when player enters the area
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if it's the player
	if body.is_in_group("player"):
		print("Coin collected! Value: ", coin_value)
		
		# Emit signal so score system can track it
		coin_collected.emit(coin_value)
		
		# Play pickup effect
		pickup_effect()
		
		# Remove the coin
		queue_free()

func pickup_effect():
	# Visual effect - float up and fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -30), 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
