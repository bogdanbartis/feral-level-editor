extends Camera2D

## The speed at which the camera will move, in pixels per second.
@export var speed: float = 300.0
@export var move_with_keys: bool = true

func _process(delta: float) -> void:
	if !move_with_keys:
		return
	
	# Get the input direction from the keyboard's arrow keys.
	# get_axis() returns a value between -1 and 1.
	var horizontal_input = Input.get_axis("move_left", "move_right")
	var vertical_input = Input.get_axis("move_up", "move_down")
	
	# Create a direction vector from the input and normalize it
	# to prevent faster movement on diagonals.
	var direction = Vector2(horizontal_input, vertical_input).normalized()

	# Update the camera's position.
	# Multiplying by 'delta' makes the movement frame-rate independent.
	position += direction * speed * delta
