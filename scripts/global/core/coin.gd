# === COIN WITH SOUND ===
extends Area2D

@export var coin_value: int = 1

@onready var sprite = $Sprite2D
@onready var pickup_sound = $PickupSound

signal coin_collected(value)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Coin collected! Value: ", coin_value)
		
		# Play sound!
		if pickup_sound:
			pickup_sound.play()
		
		coin_collected.emit(coin_value)
		pickup_effect()
		
		# Wait for sound to finish before removing
		if pickup_sound:
			await pickup_sound.finished
		
		queue_free()

func pickup_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -30), 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
