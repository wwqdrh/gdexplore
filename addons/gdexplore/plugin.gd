@tool
extends EditorPlugin

var finder: Window

func _enter_tree() -> void:
	finder = preload("editor/finder.tscn").instantiate()
	finder.theme = get_editor_interface().get_base_control().theme
	get_editor_interface().get_base_control().add_child(finder)
	add_tool_menu_item("Game Assets", _on_finder_pressed)

func _exit_tree() -> void:
	remove_tool_menu_item("Game Assets")
	if is_instance_valid(finder):
		finder.queue_free()

func _on_finder_pressed():
	#finder.show()
	finder.show_window()
