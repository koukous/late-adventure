extends CharacterBody2D
# Player movement with animations matching your exact animation names!
# Animations: idle, walk_up, walk_down, walk_left, walk_right

# Movement settings
@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Track which direction the player is facing
var facing_direction: Vector2 = Vector2.DOWN

# Reference to the AnimatedSprite2D node
@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# Get input from the player
	var input_direction = get_input_direction()
	
	# Update facing direction when moving
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction
	
	# Apply movement
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Move the character
	move_and_slide()
	
	# Update animations based on movement and direction
	update_animation()


func get_input_direction() -> Vector2:
	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	return direction.normalized()


func update_animation():
	# Check if we're moving or standing still
	var is_moving = velocity.length() > 10
	
	if is_moving:
		# Moving - play the walk animation based on which direction
		# we're moving (using facing_direction)
		
		# Determine which direction is strongest
		if abs(facing_direction.x) > abs(facing_direction.y):
			# Moving more horizontally (left or right)
			if facing_direction.x < 0:
				animated_sprite.play("walk_left")
			else:
				animated_sprite.play("walk_right")
		else:
			# Moving more vertically (up or down)
			if facing_direction.y < 0:
				animated_sprite.play("walk_up")
			else:
				animated_sprite.play("walk_down")
	else:
		# Standing still - play idle animation
		animated_sprite.play("idle")
