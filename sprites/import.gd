@tool
extends EditorScript

# The sprites directory path
var sprites_dir = "res://sprites"

# The max horizontal width in pixels allowed before to fit sprites in a row
var max_width: int = 1920

# The padding in pixels that is applied around the sprites
var sprite_padding: int = 16

# The screen scale, used to scale sprites for HiDPI displays
var screen_scale: int = 1

const CONTAINER_SCENE_PATH = "res://addons/level_editor/ui/selectable_entity.tscn"
const CONTAINER_SCENE = preload(CONTAINER_SCENE_PATH)

func _run() -> void:
	set_screen_scale()
	import()

func set_screen_scale() -> void:
	screen_scale = DisplayServer.screen_get_scale()

func import() -> void:
	# Each collection has its own folder in the sprites directory
	for dir in DirAccess.open(sprites_dir).get_directories():
		import_sprite_collection(dir)

# Import and individual sprite collection
func import_sprite_collection(collection: String) -> void:
	print("Importing sprite collection: " + collection)
	
	# Load scene
	var scene_root: Control = load_collection_scene(collection)
	
	if !scene_root:
		printerr("Skipping collection " + collection + ". No scene found.")
		
		return
	
	# Skip scene if root node is marked to be ignored by import process
	if scene_root.get_meta("import_ignore"):
		print("Ignoring collection " + collection + ".")
		
		return
	
	# Create sprites
	var sprites = create_sprite_nodes(collection)
	
	# Remove all sprites from the scene, unless marked as append only
	if !scene_root.get_meta("import_append"):
		print("Removing sprites from " + collection + ".")
		remove_sprites_from_scene(scene_root)
	
	# Add sprites to scene
	add_sprites_to_scene(scene_root, sprites)
	
	# Save scene to disk
	save_scene(scene_root, sprites_dir + "/" + collection + "/" + collection + ".tscn")

	# Position sprites in a grid pattern 
	position_sprites(scene_root)
	
	# Save scene to disk
	save_scene(scene_root, sprites_dir + "/" + collection + "/" + collection + ".tscn")
	
# Load collection scene from disk
func load_collection_scene(collection: String) -> Control:
	var collection_path = sprites_dir + "/" + collection
	var scene_path = collection_path + "/" + collection + ".tscn"
	
	if !FileAccess.file_exists(scene_path):
		printerr("No scene found at: " + scene_path)
		
		return null
	
	return load(scene_path).instantiate()

# Create all sprite nodes from sprite .png files
func create_sprite_nodes(collection: String) -> Array:
	var collection_path = sprites_dir + "/" + collection
	var graphics_path = collection_path + "/graphics"
	
	var nodes := []
	
	for filename: String in DirAccess.open(graphics_path).get_files():
		if !filename.ends_with('.png'):
			continue

		nodes.append(
			get_sprite_node(graphics_path + "/" + filename)
		)
		
	return nodes
	
# Create a sprite node structure for a file
func get_sprite_node(filepath: String) -> MarginContainer:
	var sprite_name = get_sprite_name(filepath.get_file())
	var sprite := Sprite2D.new()

	sprite.name = sprite_name
	sprite.centered = false
	sprite.texture = load(filepath)
	sprite.position = Vector2(sprite_padding, sprite_padding)
	
	var container: MarginContainer = MarginContainer.new()
	
	container.name = sprite_name
	container.size = sprite.texture.get_size() + Vector2(sprite_padding * 2, sprite_padding * 2)

	container.add_child(sprite)
	
	return container

# Get the normalized sprite name based on the filename
func get_sprite_name(filename: String):
	return filename.get_basename().replace("-", " ").to_pascal_case()

# Remove all sprites from the scene root
func remove_sprites_from_scene(scene_root: Control) -> void:
	for sprite: MarginContainer in scene_root.find_children("*", "MarginContainer", false):
		scene_root.remove_child(sprite)
		sprite.queue_free()

# Add sprites to the scene root
func add_sprites_to_scene(scene_root: Control, sprites: Array) -> void:
	for sprite in sprites:
		if !sprite_imported(scene_root, sprite.name):
			scene_root.add_child(sprite)
			prints("Add sprite:", sprite)

# Check if a sprite is already imported into the scene
func sprite_imported(scene: Control, name: String) -> bool:
	return scene.find_child(name) != null

# Position all sprites inside the collection scene with simple shelf packing
func position_sprites(scene: Control) -> void:
	var max_sprite_height: int = 0

	var offset_x: int = 0
	var offset_y: int = 0
	
	for sprite in scene.find_children("*", "MarginContainer", false):
		sprite.position.x = offset_x
		sprite.position.y = offset_y

		# Check if current sprite fits in the current row	
		if offset_x + sprite.size.x > max_width:
			# Go down a row
			offset_x = 0
			offset_y += max_sprite_height
		else:
			# Keep going on the current row
			offset_x += sprite.size.x
			# See if the current sprite heigh is the largest on the row
			max_sprite_height = max(max_sprite_height, sprite.size.y)

# Save the collection scene to disk
func save_scene(scene_root: Control, path: String) -> void:
	print("Saving collection scene to " + path + "...")
	
	# All nodes need to have a defined owner. Required to save the scene.
	set_owner(scene_root, scene_root)

	var scene = PackedScene.new()
	var pack_result = scene.pack(scene_root)

	if pack_result == OK:
		var save_result = ResourceSaver.save(scene, path)
		
		if save_result == OK:
			print("Done")
		else:
			printerr("Error saving collection scene to disk. Error code: ", save_result)
	else:
		printerr("Error packing collection scene. Error code: ", pack_result)

# Recursively set the owner of a node and all its children
func set_owner(node: Node, owner_node: Node):
	if node != owner_node:
		node.owner = owner_node

	for child in node.get_children():
		set_owner(child, owner_node)
