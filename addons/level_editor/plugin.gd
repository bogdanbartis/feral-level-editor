@tool
extends EditorPlugin

# The editor panel scene
var editor_scene: PackedScene = preload("res://addons/level_editor/ui/level_editor.tscn")

# The editor panel instance
var editor: Control

# The custom cursor that will display the selected sprite
var cursor_sprite: TextureRect

# The selected sprite node
var selected_entity: Sprite2D

var viewport_control: Control = null
var canvas_item_editor: Control = null

var editor_viewport: SubViewport = null # The 2D editor's viewport

func _enter_tree() -> void:
	load_editor()
	
	call_deferred("_setup_connections")
	
func _exit_tree() -> void:
	unload_editor()
	
	_remove_connections()
		
func load_editor() -> void:
	editor = editor_scene.instantiate()
	editor.connect("entity_selected", _entity_selected)
	
	add_control_to_bottom_panel(editor, "Level Editor")

func unload_editor() -> void:
	if is_instance_valid(editor):
		remove_control_from_bottom_panel(editor)
		editor.queue_free()

func _setup_connections():
	# Find the specific control for the 2D editor viewport.
	# Its class name is "CanvasItemEditorViewport".
	viewport_control = _find_control_by_class(get_editor_interface().get_base_control(), "CanvasItemEditorViewport")
	canvas_item_editor = _find_control_by_class(get_editor_interface().get_base_control(), "CanvasItemEditor")
	
	# --- Create the custom cursor sprite ---
	cursor_sprite = TextureRect.new()
	cursor_sprite.name = "EditorCustomCursor" # Give it a unique name
	#cursor_sprite.scale = Vector2(2.0, 2.0)
	cursor_sprite.hide() # The cursor should be hidden by default.
	cursor_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Add the sprite to the editor's main UI so it can be drawn on top of everything.
	get_editor_interface().get_base_control().add_child(cursor_sprite)

	editor_viewport = get_editor_interface().get_editor_viewport_2d()

	if viewport_control and editor_viewport:
		print("2D Viewport Detector: Viewport found. Connecting signals.")
		# Connect to the signals we care about.
		viewport_control.mouse_entered.connect(_on_mouse_entered_viewport)
		viewport_control.mouse_exited.connect(_on_mouse_exited_viewport)
	else:
		printerr("2D Viewport Detector: Could not find the required editor controls.")

func _remove_connections():
	if is_instance_valid(viewport_control):
		#print("2D Viewport Detector: Disconnecting signals.")
		viewport_control.mouse_entered.disconnect(_on_mouse_entered_viewport)
		viewport_control.mouse_exited.disconnect(_on_mouse_exited_viewport)

func _process(_delta):
	# This function runs every frame in the editor.
	# We update the sprite's position to follow the mouse.
	#if is_instance_valid(cursor_sprite):
		## Get the current zoom level from the 2D editor.
		#var current_zoom = canvas_item_editor.zoom
		## This makes the cursor icon scale as if it's part of the world.
		#cursor_sprite.scale = current_zoom * 2
		#var scaled_offset = (cursor_sprite.size * cursor_sprite.scale) / 2.0
		##cursor_sprite.global_position = get_editor_interface().get_edited_scene_root().get_global_mouse_position()
		##cursor_sprite.global_position = get_editor_interface().get_mouse_position() - (cursor_sprite.size / 2)
		##cursor_sprite.global_position = get_editor_interface().get_base_control().get_global_mouse_position() - (cursor_sprite.size / 2)
		#cursor_sprite.global_position = get_editor_interface().get_base_control().get_global_mouse_position() - scaled_offset
		
	
	if is_instance_valid(cursor_sprite) and is_instance_valid(canvas_item_editor) and is_instance_valid(editor_viewport):
		# Get the viewport's canvas_transform, which contains the zoom level.
		var canvas_transform: Transform2D = editor_viewport.global_canvas_transform
		
		# The scale of the transform is the visual zoom.
		var current_scale: Vector2 = canvas_transform.get_scale()
		
		# Update the sprite's scale based on the zoom.
		cursor_sprite.scale = current_scale
		
		# Update the sprite's position to follow the mouse
		cursor_sprite.global_position = get_editor_interface().get_base_control().get_global_mouse_position()
			
func _on_mouse_entered_viewport():
	#print("Mouse ENTERED the 2D viewport.")
	if selected_entity:
		if is_instance_valid(cursor_sprite):
			cursor_sprite.show()
		
			# Hide the default OS cursor when inside the viewport.
			#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_mouse_exited_viewport():
	#print("Mouse EXITED the 2D viewport.")
	
	if is_instance_valid(cursor_sprite):
		cursor_sprite.hide()
	# Show the default OS cursor when we leave the viewport.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- Helper Function ---

func _find_control_by_class(start_node: Control, classname: String) -> Control:
	"""
	Recursively searches the editor's scene tree to find a Control node
	of a specific class name.
	"""
	if start_node.get_class() == classname:
		return start_node

	for child in start_node.get_children():
		if child is Control:
			var found = _find_control_by_class(child, classname)
			if found:
				return found
	
	return null

func _entity_selected(entity: MarginContainer) -> void:
	selected_entity = entity.find_children("*", "Sprite2D", false)[0]
	
	cursor_sprite.texture = selected_entity.texture
	cursor_sprite.size = selected_entity.texture.get_size()
	#cursor_sprite.z_index = 1000
	
	#cursor_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

	
	#print("Selected: ", selected_entity)
		
func _handles(object: Object):
	return true

func _forward_canvas_gui_input(event: InputEvent) -> bool:	
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	
	if event is InputEventKey:
		#print("input key event")
		# Check if the key is pressed (not released) and if its scancode matches KEY_ESCAPE.
		if event.is_pressed() and event.keycode == KEY_ESCAPE:
			#print("Plugin caught the Escape key!")
			
			selected_entity = null
			cursor_sprite.hide()
	
	if !selected_entity:
		return false
		
	# 1. We only care about unhandled left mouse button presses.
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
		var edited_scene_root = get_editor_interface().get_edited_scene_root()
		
		#print(edited_scene_root)
		# 3. Ensure a scene is currently being edited.
		if not edited_scene_root:
			return false

		# 4. Get the 2D viewport to calculate the mouse position in world coordinates.
		var viewport_2d = get_editor_interface().get_editor_viewport_2d()
		
		#var world_mouse_position = viewport_2d.get_canvas_transform().affine_inverse() * event.position
		
		#var local_mouse_pos = viewport_2d.get_local_mouse_position()
		#var world_mouse_position = viewport_2d.get_canvas_transform().affine_inverse() * local_mouse_pos
		var world_mouse_position = edited_scene_root.get_global_mouse_position()

		# 5. Create the new Sprite2D node.
		var sprite = selected_entity.duplicate()
		sprite.global_position = world_mouse_position

		# 6. Use UndoRedoManager to add the node so the action is undoable (Ctrl+Z).
		var undo_redo = get_undo_redo()
		undo_redo.create_action("Add Sprite2D")
		undo_redo.add_do_method(edited_scene_root, "add_child", sprite)
		# This step is CRUCIAL. It ensures the new node is saved with the scene.
		undo_redo.add_do_property(sprite, "owner", edited_scene_root)
		undo_redo.add_undo_method(edited_scene_root, "remove_child", sprite)
		undo_redo.commit_action()
		
		#print("added sprite2d")

	# 7. Mark the input as handled to prevent other actions (like node selection).
	#viewport_2d.set_input_as_handled()
		
	return true
