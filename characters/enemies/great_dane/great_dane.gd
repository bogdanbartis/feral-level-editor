@tool
extends CharacterBody2D

@export var flip: bool = false:
	set(value):
		flip = value
		$AnimatedSprite2D.flip_h = flip


func _ready() -> void:
	$AnimatedSprite2D.flip_h = flip
