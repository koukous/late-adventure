extends Area2D

@export var item_data: ItemData
@export var quantity: int = 1

@onready var sprite = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	
	if item_data and item_data.icon:
		sprite.texture = item_data.icon

func _on_body_entered(body):
	if body.is_in_group("player"):
		var inventory = get_node("/root/InventoryManager")
		if inventory and item_data:
			inventory.add_item(item_data, quantity)
			
			# Visual effect
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(self, "position", position + Vector2(0, -30), 0.3)
			tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
			tween.tween_callback(queue_free).set_delay(0.3)
