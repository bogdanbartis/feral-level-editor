@tool
extends Control

# Emitted when the user clicks an entity
signal entity_selected

# The sprites directory path
var sprites_dir = "res://sprites"

# The padding in pixels that is applied around the sprites
var sprite_padding: int = 16

# The zoom value, used to visually scale the collection entities in the panel
var zoom: int = 1

# A color selection 
var selection_rect := Panel.new()

# The selected entity
var selected_entity: MarginContainer

# A cache store for all the loaded entity collections
var entity_cache: Dictionary

func _ready():
	init_selection_rect()
	load_sprites_collections()

func init_selection_rect() -> void:
	var stylebox = StyleBoxFlat.new()
	
	stylebox.set_corner_radius_all(4)
	stylebox.bg_color = Color(255, 255, 255, 0.25)
	
	selection_rect.add_theme_stylebox_override("panel", stylebox)
	selection_rect.size

func load_sprites_collections():
	for collection in DirAccess.open(sprites_dir).get_directories():
		var scene_root = load_sprite_collection_scene(collection)
		
		if !scene_root:
			printerr("Cannot load sprite collection scene for: " + collection)
		
			continue

		add_entity_collection(scene_root)
		
func load_sprite_collection_scene(collection: String) -> Control:
	var scene_path = sprites_dir + "/" + collection + "/" + collection + ".tscn"
	
	if !FileAccess.file_exists(scene_path):
		printerr("No scene found at: " + scene_path)
		
		return null
	
	return load(scene_path).instantiate()
	
func add_entity_collection(scene_root: Control) -> void:
	var scroll_container := ScrollContainer.new()
	
	scroll_container.name = scene_root.name.capitalize()
	scroll_container.add_child(scene_root)
	
	entity_cache.set(scroll_container.name, scene_root.find_children("*", "MarginContainer", false))
	
	register_entity_event_handlers(scroll_container.name)
	
	%EntityCollections.add_child(scroll_container)

func register_entity_event_handlers(collection: String) -> void:
	for entity in entity_cache.get(collection):
		entity.connect("gui_input", _on_entity_gui_input.bind(entity))

func select_entity(entity: MarginContainer) -> void:
	if selected_entity:
		selected_entity.remove_child(selection_rect)
					
	selected_entity = entity

	entity.add_child(selection_rect)
	entity.move_child(selection_rect, 0)

	selection_rect.size = entity.size + Vector2(sprite_padding * 2, sprite_padding * 2)
	selection_rect.position = Vector2(-sprite_padding, -sprite_padding)
	
	entity_selected.emit(entity)
		
func _on_entity_gui_input(event: InputEvent, entity: MarginContainer) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			select_entity(entity)
			
			get_viewport().set_input_as_handled()

func _on_spin_box_value_changed(value: float) -> void:
	for collection in entity_cache:
		for entity: MarginContainer in entity_cache[collection]:
			entity.scale = Vector2(value, value)

		position_entities(collection)
		
func position_entities(collection) -> void:
	var max_width: int = 1920
	var max_entity_height: int = 0

	var offset_x: int = 0
	var offset_y: int = 0
	
	for entity in entity_cache[collection]:
		entity.position.x = offset_x
		entity.position.y = offset_y
		
		# Check if current entity fits in the current row	
		if offset_x + entity.size.x > max_width:
			# Go down a row
			offset_x = 0
			offset_y += max_entity_height * entity.scale.y
		else:
			# Keep going on the current row
			offset_x += entity.size.x * entity.scale.x
			# See if the current entity heigh is the largest on the row
			max_entity_height = max(max_entity_height, entity.size.y)
