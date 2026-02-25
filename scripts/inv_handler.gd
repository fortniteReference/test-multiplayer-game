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
		
		title.text = item.get_meta("name")
		if item.get_meta("image") != "":
			image.texture = load(str(item.get_meta("image")))
		
		var pressed_view = func():
			view_title.text = str(title.text)
			view_desc.text = item.get_meta("description")
			view_rarity.text = item.get_meta("rarity")
			view_rarity.add_theme_color_override("font_color", item.get_meta("slot_color"))
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
	if current_id.containsn("color"):
		for id in equipped_items:
			if id.containsn("color"): equipped_items.erase(id)
	for item in items.get_children():
		if item.get_meta("id") == current_id and not equipped_items.has(current_id): equipped_items.append(current_id)

func _on_locker_pressed() -> void:
	create_slots()
