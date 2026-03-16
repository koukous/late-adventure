extends Area2D
# Gatherable resource - flowers, herbs, wood, etc.

@export var resource_item: ItemData  # What item this gives
@export var resource_amount: int = 1
@export var respawn_time: float = 30.0  # Seconds to respawn

var player_in_range: bool = false
var is_gathered: bool = false
var prompt_label: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	prompt_label = get_node_or_null("PromptLabel")
	if prompt_label:
		prompt_label.visible = false

func _on_body_entered(body):
	if body.is_in_group("player") and not is_gathered:
		player_in_range = true
		show_prompt()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()

func _process(_delta):
	if player_in_range and not is_gathered and Input.is_action_just_pressed("ui_accept"):
		gather()

func gather():
	is_gathered = true
	player_in_range = false
	hide_prompt()
	
	# Add to inventory
	var inventory = get_node("/root/InventoryManager")
	if inventory and resource_item:
		inventory.add_item(resource_item, resource_amount)
		print("Gathered ", resource_amount, "x ", resource_item.item_name)
	
	# Hide visual
	visible = false
	
	# Respawn after time
	await get_tree().create_timer(respawn_time).timeout
	respawn()

func respawn():
	is_gathered = false
	visible = true
	print("Resource respawned!")

func show_prompt():
	if prompt_label:
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
