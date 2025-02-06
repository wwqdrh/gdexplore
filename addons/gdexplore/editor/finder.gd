@tool
extends AcceptDialog

# sprite page
@onready var sprite_grid: GridContainer = $VBoxContainer/TabContainer/Images/ScrollContainer/GridContainer
@onready var sprite_pagination: HBoxContainer = $VBoxContainer/TabContainer/Images/PaginationContainer
@onready var sprite_page_label: Label = $VBoxContainer/TabContainer/Images/PaginationContainer/PageLabel

# hud page
@onready var hud_grid: GridContainer = $VBoxContainer/TabContainer/Hud/ScrollContainer/GridContainer
@onready var hud_pagination: HBoxContainer = $VBoxContainer/TabContainer/Hud/PaginationContainer
@onready var hud_page_label: Label = $VBoxContainer/TabContainer/Hud/PaginationContainer/PageLabel

# audio page
@onready var audio_list: VBoxContainer = $VBoxContainer/TabContainer/Audio/ScrollContainer/AudioList
@onready var pagination_container: HBoxContainer = $VBoxContainer/TabContainer/Audio/PaginationContainer
@onready var page_label: Label = $VBoxContainer/TabContainer/Audio/PaginationContainer/PageLabel

# bgm page
@onready var bgm_list: VBoxContainer = $VBoxContainer/TabContainer/Bgm/ScrollContainer/AudioList
@onready var bgm_pagination_container: HBoxContainer = $VBoxContainer/TabContainer/Bgm/PaginationContainer
@onready var bgm_page_label: Label = $VBoxContainer/TabContainer/Bgm/PaginationContainer/PageLabel

# icons page
@onready var icon_grid: GridContainer = $VBoxContainer/TabContainer/Icons/ScrollContainer/GridContainer
@onready var icon_pagination: HBoxContainer = $VBoxContainer/TabContainer/Icons/PaginationContainer
@onready var icon_page_label: Label = $VBoxContainer/TabContainer/Icons/PaginationContainer/PageLabel
@onready var folder_buttons: HBoxContainer = $VBoxContainer/TabContainer/Icons/FolderButtons

# utils
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var confirm_dialog: ConfirmationDialog = $ConfirmationDialog

var first_popup: bool = true
var audio_files: Array = []
var bgm_files: Array = []
var sprite_files: Array = []
var hud_files: Array = []
var current_audio_page: int = 1
var current_bgm_page: int = 1
var current_sprite_page: int = 1
var current_hud_page: int = 1
const ITEMS_PER_PAGE: int = 10
const THUMBNAIL_SIZE = 100
var selected_file: Dictionary # 用于存储当前选中的文件信息
var icon_files: Array = []
var current_icon_page: int = 1
var current_icon_folder: String = ""
var icon_folders: Array = []

func _ready() -> void:
	load_audio_files()
	load_bgm_files()
	load_sprite_files()
	load_hud_files()
	load_icon_folders()
	
	# 设置确认对话框
	confirm_dialog.dialog_text = "Are you sure you want to delete this file?"
	confirm_dialog.confirmed.connect(_on_confirm_delete)

func show_window() -> void:
	if first_popup:
		popup_centered()
		first_popup = false
	else:
		popup()

func load_audio_files() -> void:
	var dir = DirAccess.open("res://assets/audio")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() in ["wav", "mp3", "ogg"]:
				audio_files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		update_audio_page_display()

func load_bgm_files() -> void:
	var dir = DirAccess.open("res://assets/bgm")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() in ["wav", "mp3", "ogg"]:
				bgm_files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		update_bgm_page_display()

func load_sprite_files() -> void:
	sprite_files.clear()
	load_images_from_directory("res://assets/sprite", sprite_files)
	update_sprite_page_display()

func load_hud_files() -> void:
	hud_files.clear()
	load_images_from_directory("res://assets/hud", hud_files)
	update_hud_page_display()

func load_images_from_directory(path: String, files_array: Array) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() in ["png", "jpg", "jpeg"]:
				files_array.append({"path": path + "/" + file_name, "name": file_name})
			file_name = dir.get_next()
		dir.list_dir_end()

func update_sprite_page_display() -> void:
	update_image_page_display(sprite_files, sprite_grid, current_sprite_page, sprite_page_label)

func update_hud_page_display() -> void:
	update_image_page_display(hud_files, hud_grid, current_hud_page, hud_page_label)

func update_image_page_display(files: Array, grid: GridContainer, current_page: int, page_label: Label) -> void:
	# Clear existing items
	for child in grid.get_children():
		child.queue_free()
	
	# Calculate total pages
	var total_pages = ceili(float(files.size()) / ITEMS_PER_PAGE)
	current_page = mini(current_page, total_pages)
	current_page = maxi(current_page, 1)
	
	# Update page label
	page_label.text = "Page %d/%d" % [current_page, total_pages]
	
	# Calculate start and end indices for current page
	var start_idx = (current_page - 1) * ITEMS_PER_PAGE
	var end_idx = mini(start_idx + ITEMS_PER_PAGE, files.size())
	
	# Create items for current page
	for i in range(start_idx, end_idx):
		create_image_item(files[i], grid)

func create_image_item(image_data: Dictionary, grid: GridContainer) -> void:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(THUMBNAIL_SIZE, THUMBNAIL_SIZE + 30)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create TextureRect for thumbnail
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(THUMBNAIL_SIZE, THUMBNAIL_SIZE)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Make texture_rect clickable
	texture_rect.gui_input.connect(func(event): _on_image_clicked(event, image_data))
	texture_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Load and set the texture
	var texture = load(image_data.path)
	if texture:
		texture_rect.texture = texture
	
	# Create label for file name
	var label = Label.new()
	label.text = image_data.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.tooltip_text = image_data.name
	
	vbox.add_child(texture_rect)
	vbox.add_child(label)
	grid.add_child(vbox)

func update_audio_page_display() -> void:
	# Clear existing items
	for child in audio_list.get_children():
		child.queue_free()
	
	# Calculate total pages
	var total_pages = ceili(float(audio_files.size()) / ITEMS_PER_PAGE)
	current_audio_page = mini(current_audio_page, total_pages)
	current_audio_page = maxi(current_audio_page, 1)
	
	# Update page label
	page_label.text = "Page %d/%d" % [current_audio_page, total_pages]
	
	# Calculate start and end indices for current page
	var start_idx = (current_audio_page - 1) * ITEMS_PER_PAGE
	var end_idx = mini(start_idx + ITEMS_PER_PAGE, audio_files.size())
	
	# Create items for current page
	for i in range(start_idx, end_idx):
		create_audio_item(audio_files[i])

func update_bgm_page_display() -> void:
	# Clear existing items
	for child in bgm_list.get_children():
		child.queue_free()
	
	# Calculate total pages
	var total_pages = ceili(float(bgm_files.size()) / ITEMS_PER_PAGE)
	current_bgm_page = mini(current_bgm_page, total_pages)
	current_bgm_page = maxi(current_bgm_page, 1)
	
	# Update page label
	bgm_page_label.text = "Page %d/%d" % [current_bgm_page, total_pages]
	
	# Calculate start and end indices for current page
	var start_idx = (current_bgm_page - 1) * ITEMS_PER_PAGE
	var end_idx = mini(start_idx + ITEMS_PER_PAGE, bgm_files.size())
	
	# Create items for current page
	for i in range(start_idx, end_idx):
		create_bgm_item(bgm_files[i])

func create_audio_item(file_name: String) -> void:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = file_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var play_button = Button.new()
	play_button.text = "Play"
	play_button.pressed.connect(func(): play_audio(file_name))
	
	var stop_button = Button.new()
	stop_button.text = "Stop"
	stop_button.pressed.connect(func(): stop_audio())
	
	# Add delete button
	var delete_button = Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(func(): _on_audio_delete_pressed(file_name))
	
	hbox.add_child(label)
	hbox.add_child(play_button)
	hbox.add_child(stop_button)
	hbox.add_child(delete_button)
	
	audio_list.add_child(hbox)

func create_bgm_item(file_name: String) -> void:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = file_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var play_button = Button.new()
	play_button.text = "Play"
	play_button.pressed.connect(func(): play_audio(file_name))
	
	var stop_button = Button.new()
	stop_button.text = "Stop"
	stop_button.pressed.connect(func(): stop_audio())
	
	# Add delete button
	var delete_button = Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(func(): _on_audio_delete_pressed(file_name))
	
	hbox.add_child(label)
	hbox.add_child(play_button)
	hbox.add_child(stop_button)
	hbox.add_child(delete_button)
	
	bgm_list.add_child(hbox)

func play_audio(file_name: String) -> void:
	var audio_path = "res://assets/audio/" + file_name
	var stream = load(audio_path)
	if stream:
		audio_player.stream = stream
		audio_player.play()

func stop_audio() -> void:
	audio_player.stop()

func _on_prev_sprite_page_pressed() -> void:
	current_sprite_page -= 1
	update_sprite_page_display()

func _on_next_sprite_page_pressed() -> void:
	current_sprite_page += 1
	update_sprite_page_display()

func _on_prev_audio_page_pressed() -> void:
	current_audio_page -= 1
	update_audio_page_display()

func _on_next_audio_page_pressed() -> void:
	current_audio_page += 1
	update_audio_page_display()

func _on_prev_bgm_page_pressed() -> void:
	current_bgm_page -= 1
	update_bgm_page_display()

func _on_next_bgm_page_pressed() -> void:
	current_bgm_page += 1
	update_bgm_page_display()

func _on_prev_hud_page_pressed() -> void:
	current_hud_page -= 1
	update_hud_page_display()

func _on_next_hud_page_pressed() -> void:
	current_hud_page += 1
	update_hud_page_display()

func _on_image_clicked(event: InputEvent, image_data: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_file = image_data
		var popup = PopupMenu.new()
		popup.add_item("Delete")
		popup.id_pressed.connect(_on_image_popup_selected)
		get_window().add_child(popup)
		
		# 获取点击的全局位置
		var click_pos = (event as InputEventMouseButton).global_position
		# 弹出菜单
		popup.popup()
		popup.position = click_pos
		# 确保popup在使用后被清理
		popup.popup_hide.connect(func(): popup.queue_free())

func _on_image_popup_selected(id: int) -> void:
	if id == 0: # Delete option
		confirm_dialog.dialog_text = "Are you sure you want to delete %s?" % selected_file.name
		confirm_dialog.popup_centered()

func _on_audio_delete_pressed(file_name: String) -> void:
	selected_file = {"path": "res://assets/audio/" + file_name, "name": file_name}
	confirm_dialog.dialog_text = "Are you sure you want to delete %s?" % file_name
	confirm_dialog.popup_centered()

func _on_confirm_delete() -> void:
	var file_path = selected_file.path
	
	# Delete the file
	if DirAccess.remove_absolute(file_path) == OK:
		# Refresh the appropriate list based on the file path
		if "audio" in file_path:
			audio_files.erase(selected_file.name)
			update_audio_page_display()
		if "bgm" in file_path:
			bgm_files.erase(selected_file.name)
			update_bgm_page_display()
		elif "hud" in file_path:
			hud_files.erase(selected_file)
			update_hud_page_display()
		elif "sprite" in file_path:
			sprite_files.erase(selected_file)
			update_sprite_page_display()
		elif "icons" in file_path:
			icon_files.erase(selected_file)
			update_icon_page_display()
		
		# Show success message
		var success_dialog = AcceptDialog.new()
		success_dialog.dialog_text = "File deleted successfully!"
		add_child(success_dialog)
		success_dialog.popup_centered()
		success_dialog.confirmed.connect(func(): success_dialog.queue_free())
	else:
		# Show error message
		var error_dialog = AcceptDialog.new()
		error_dialog.dialog_text = "Error deleting file!"
		add_child(error_dialog)
		error_dialog.popup_centered()
		error_dialog.confirmed.connect(func(): error_dialog.queue_free())

func load_icon_folders() -> void:
	icon_folders.clear()
	# 获取icons目录下的所有文件夹
	var dir = DirAccess.open("res://assets/icons")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				icon_folders.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		# 创建文件夹按钮
		create_folder_buttons()
		
		# 如果有文件夹，默认加载第一个
		if icon_folders.size() > 0:
			load_icon_files(icon_folders[0])

func create_folder_buttons() -> void:
	# 清除现有按钮
	for child in folder_buttons.get_children():
		child.queue_free()
	
	# 为每个文件夹创建按钮
	for folder in icon_folders:
		var button = Button.new()
		button.text = folder
		button.toggle_mode = true
		button.button_pressed = folder == current_icon_folder
		button.pressed.connect(func(): _on_folder_button_pressed(folder))
		folder_buttons.add_child(button)

func _on_folder_button_pressed(folder_name: String) -> void:
	# 更新按钮状态
	for button in folder_buttons.get_children():
		button.button_pressed = button.text == folder_name
	
	# 加载选中文件夹的内容
	current_icon_folder = folder_name
	current_icon_page = 1
	load_icon_files(folder_name)

func load_icon_files(folder_name: String) -> void:
	icon_files.clear()
	var path = "res://assets/icons/" + folder_name
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension() in ["png", "jpg", "jpeg"]:
				icon_files.append({
					"path": path + "/" + file_name,
					"name": file_name
				})
			file_name = dir.get_next()
		dir.list_dir_end()
		
		update_icon_page_display()

func update_icon_page_display() -> void:
	# Clear existing items
	for child in icon_grid.get_children():
		child.queue_free()
	
	# Calculate total pages
	var total_pages = ceili(float(icon_files.size()) / ITEMS_PER_PAGE)
	current_icon_page = mini(current_icon_page, total_pages)
	current_icon_page = maxi(current_icon_page, 1)
	
	# Update page label
	icon_page_label.text = "Page %d/%d" % [current_icon_page, total_pages]
	
	# Calculate start and end indices for current page
	var start_idx = (current_icon_page - 1) * ITEMS_PER_PAGE
	var end_idx = mini(start_idx + ITEMS_PER_PAGE, icon_files.size())
	
	# Create items for current page
	for i in range(start_idx, end_idx):
		create_icon_item(icon_files[i])

func create_icon_item(item_data: Dictionary) -> void:
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(THUMBNAIL_SIZE, THUMBNAIL_SIZE + 30)
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Create TextureRect for thumbnail
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(THUMBNAIL_SIZE, THUMBNAIL_SIZE)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.gui_input.connect(func(event): _on_image_clicked(event, item_data))
	texture_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var texture = load(item_data.path)
	if texture:
		texture_rect.texture = texture
	
	# Create label for file name
	var label = Label.new()
	label.text = item_data.name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.tooltip_text = item_data.name
	
	vbox.add_child(texture_rect)
	vbox.add_child(label)
	icon_grid.add_child(vbox)

func _on_prev_icon_page_pressed() -> void:
	current_icon_page -= 1
	update_icon_page_display()

func _on_next_icon_page_pressed() -> void:
	current_icon_page += 1
	update_icon_page_display()
