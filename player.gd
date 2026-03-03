extends CharacterBody2D
# This is the main script for your player character
# CharacterBody2D is perfect for characters that need physics and collision

# Movement settings - you can adjust these numbers to change how your character feels
@export var speed: float = 200.0  # How fast the player moves (pixels per second)
@export var acceleration: float = 1500.0  # How quickly the player speeds up
@export var friction: float = 1200.0  # How quickly the player slows down

# We'll use these later for more advanced features
var facing_direction: Vector2 = Vector2.DOWN  # Which way the player is facing

func _physics_process(delta):
	# This function runs every physics frame (usually 60 times per second)
	# delta is the time since the last frame (usually 0.016 seconds)
	
	# STEP 1: Get input from the player
	var input_direction = get_input_direction()
	
	# STEP 2: Update which way we're facing (if we're moving)
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction
	
	# STEP 3: Apply movement with smooth acceleration/deceleration
	if input_direction != Vector2.ZERO:
		# Player is pressing movement keys - accelerate in that direction
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
	else:
		# Player isn't pressing anything - slow down with friction
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# STEP 4: Actually move the character
	move_and_slide()
	# move_and_slide() is a built-in function that:
	# - Moves the character based on velocity
	# - Handles collisions automatically
	# - Slides along walls smoothly


func get_input_direction() -> Vector2:
	# Get keyboard input and convert it to a direction vector
	# Vector2(x, y) where:
	# - x: -1 is left, 1 is right, 0 is no horizontal input
	# - y: -1 is up, 1 is down, 0 is no vertical input
	
	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),  # Horizontal
		Input.get_axis("move_up", "move_down")      # Vertical
	)
	
	# Normalize to prevent diagonal movement from being faster
	# (Without this, moving diagonally would be 1.4x faster!)
	return direction.normalized()
