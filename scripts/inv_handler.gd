extends Node

@onready var canvas = $Canvas
@onready var container = $Canvas/main/container/grid
@onready var og_slot = $Canvas/main/slot
@onready var items = $"../Shop Handler/Items"
# --------------------------
@onready var view_title = $Canvas/main/view/title
@onready var view_desc = $Canvas/main/view/desc
@onready var view_rarity = $Canvas/main/view/rarity
@onready var view_image = $Canvas/main/view/image
@onready var view_button = $Canvas/main/view/equip

var current_id = ""
var owned_items = []
var equipped_items = []

func play_lobby_music():
	for id: String in equipped_items:
		if not id.contains("lobby_"): continue
		
		var item: Node = null
		for item_node in items.get_children():
			if item_node.get_meta("id").contains(str(id)):
				item = item_node
		if item == null: continue
		
		var reference = item.get_meta("reference")
		var sound: AudioStreamPlayer = item.get_node(reference)
		sound.play()
		
func create_slots():
	canvas.show()
	view_title.text = ""
	view_desc.text = ""
	view_rarity.text = ""
	view_image.texture = null
	view_button.hide()
	
	owned_items = $"../Data Handler".items
	
	for slot in container.get_children(): slot.queue_free()
	
	for shop_item in owned_items:
		var item: Node = null
		for item_node in items.get_children():
			if item_node.get_meta("id").contains(str(shop_item)):
				item = item_node
		if item == null: continue
		
		var type_reference = item.get_node(item.get_meta("reference"))
		var type_display = ""
		if type_reference:
			if type_reference.color_enabled:
				type_display = "Color"
			elif type_reference.lobby_music_enabled:
				type_display = "Lobby Music"
			elif type_reference.accessory_enabled:
				type_display = type_reference.acc_part_display + " Accessory"
		
		var slot: Panel = og_slot.duplicate()
		container.add_child(slot)
		slot.show()
		var flat: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()
		
		flat.bg_color = item.get_meta("slot_color")
		flat.border_color = item.get_meta("slot_color").darkened(0.2)
		slot.add_theme_stylebox_override("panel", flat)
		
		var title: Label = slot.get_node("title")
		var image: TextureRect = slot.get_node("image")
		var view: Button = slot.get_node("view")
		var type: Label = slot.get_node("type")
		
		type.text = type_display
		title.text = item.get_meta("name")
		if item.get_meta("image") != "":
			image.texture = load(str(item.get_meta("image")))
		
		var font = title.get_theme_font("font")
		var current_size = 40
	
		# Use TextLine to measure text width without rendering it
		var text_measurement = TextLine.new()
	
		for i in range(40):
			text_measurement.clear()
			text_measurement.add_string(str(title.text), font, current_size)
		
			# If the measured width fits in the current label width, we're done
			if text_measurement.get_line_width() <= title.size.x:
				break
			current_size -= 1
	
		title.add_theme_font_size_override("font_size", current_size)
		
		var pressed_view = func():
			var text: String = str(item.get_meta("description"))
			view_title.text = str(title.text)
			view_desc.text = text.replace("(n)", "\n")
			view_rarity.text = item.get_meta("rarity")
			view_rarity.add_theme_color_override("font_color", item.get_meta("slot_color"))
			view_rarity.add_theme_color_override("font_outline_color", item.get_meta("slot_color").darkened(0.3))
			if item.get_meta("image") != "":
				view_image.texture = load(str(item.get_meta("image")))
			current_id = item.get_meta("id")
			
			var found_item = false
			for eq_item in equipped_items:
				if eq_item == current_id:
					found_item = true
			if found_item:
				view_button.hide()
			else:
				view_button.show()
			print(equipped_items)
			
		view.pressed.connect(pressed_view)

func _on_exit_pressed() -> void:
	canvas.hide()

func _on_equip_pressed() -> void:
	view_button.hide()
	if current_id.containsn("color_"):
		for id in equipped_items:
			if id.containsn("color_"): equipped_items.erase(id)
	if current_id.containsn("lobby_"):
		for id in equipped_items:
			if id.containsn("lobby_"): equipped_items.erase(id)
	for item in items.get_children():
		if item.get_meta("id") == current_id and not equipped_items.has(current_id): equipped_items.append(current_id)
	
	if current_id.containsn("lobby_"):
		for music in $"../Shop Handler/Lobby Music".get_children():
			if music.playing: music.stop()
		play_lobby_music()

func _on_locker_pressed() -> void:
	create_slots()
