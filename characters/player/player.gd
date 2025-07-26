# This script is attached to a CharacterBody2D root node.
# The CharacterBody2D should have an AnimatedSprite2D and a CollisionShape2D as children.
# Make sure your animations in the AnimatedSprite2D are named "idle", "run", and "jump".

extends CharacterBody2D

# --- Player Movement Variables ---
@export var speed = 200.0
@export var jump_velocity = 300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Node References ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var footstep_sound = $AudioStreamPlayer2D


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# "ui_right" and "ui_left" are the default inputs for the right and left arrow keys.
	# You can change them in Project > Project Settings > Input Map.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
	# --- Animation Logic ---
	# We call a separate function to keep the code organized.
	update_animation()

	# This is the core function that moves the character.
	move_and_slide()


# This function contains all the logic for updating the character's animation.
func update_animation():
	var direction = sign(velocity.x) # -1 for left, 1 for right, 0 for still

	# --- Flipping the Sprite ---
	# Flip the sprite based on the direction of movement.
	if direction == 1:
		animated_sprite.flip_h = false
	elif direction == -1:
		animated_sprite.flip_h = true

	# --- Animation State Machine ---
	# This logic decides which animation to play.
	if is_on_floor():
		if velocity.x == 0:
			# If the character is on the floor and not moving, play "idle".
			animated_sprite.play("idle")
		else:
			# If the character is on the floor and moving, play "run".
			animated_sprite.play("run")
	else:
		# If the character is in the air, play "jump".
		animated_sprite.play("jump")


func _on_animated_sprite_2d_frame_changed() -> void:
	# Define which frames should trigger a footstep
	var footstep_frames = [5, 12] # <-- IMPORTANT: Change these to match your animation!

	# Check if the current animation is "walk" AND if the current frame is in our list
	if animated_sprite.animation == "run" and animated_sprite.frame in footstep_frames:
		# Randomize the pitch to make it sound more natural
		footstep_sound.pitch_scale = randf_range(0.9, 1.1)
		footstep_sound.play()
