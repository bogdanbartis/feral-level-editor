@tool
extends MarginContainer

signal selected(container)

var border_color: Color = Color(255, 255, 255, 0.75)
var is_selected: bool = false

func _draw() -> void:
	if is_selected:
		var local_rect = Rect2(Vector2.ZERO, self.size)
		draw_rect(local_rect, border_color, false, 2)

func select() -> void:
	is_selected = true
	queue_redraw()

func deselect() -> void:
	is_selected = false
	queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		selected.emit(self)

		accept_event()
