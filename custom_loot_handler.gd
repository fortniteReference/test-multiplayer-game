extends Control

@onready var player = $"../.."
@onready var options = $Options
@onready var primary = $Main/Primary
@onready var secondary = $Main/Secondary

@export var current_primary: String = ""
@export var current_secondary: String = ""

func start_custom():
	var first_camera = player.get_node("Camera3D")
	
	if not first_camera: return
	clear_slots(true, true)
	if player.name == str(GDSync.get_client_id()): show()
	else: hide()
	
	current_primary = ""
	current_secondary = ""
	
	var current_slots: Control = null
	for option in options.primary_choices:
		var item = first_camera.get_node_or_null(str(option))
		if not item: continue
		
		var slots = $Main/Primary/Slots
		
		if slots.has_node("cloned slot: " + str(option)): continue
		var og_slot = $Main/Primary/Slot
		var slot = og_slot.duplicate()
		slots.add_child(slot)
		slot.position = Vector2.ZERO
		slot.name = "cloned slot: " + str(option)
		slot.show()
		
		var button: Button = slot.get_node("Select")
		var image: TextureRect = slot.get_node("Image")
		var title: Label = slot.get_node("Title")
		
		var cur_image: TextureRect = $Main/Current/Primary/Image
		var cur_text: Label = $Main/Current/Primary/Item
		
		image.texture = load(item.image)
		title.text = str(option)
		
		var pressed_select = func():
			current_primary = str(option)
			cur_image.texture = load(item.image)
			cur_text.text = str(title.text)
			
		button.pressed.connect(pressed_select)
		
		current_slots = slots
	check_slots(current_slots, options.primary_choices)
	for option in options.secondary_choices:
		var item = first_camera.get_node_or_null(str(option))
		if not item: continue
		
		var slots = $Main/Secondary/Slots
		
		if slots.has_node("cloned slot: " + str(option)): continue
		var og_slot = $Main/Secondary/Slot
		var slot = og_slot.duplicate()
		slots.add_child(slot)
		slot.position = Vector2.ZERO
		slot.name = "cloned slot: " + str(option)
		slot.show()
		
		var button: Button = slot.get_node("Select")
		var image: TextureRect = slot.get_node("Image")
		var title: Label = slot.get_node("Title")
		
		var cur_image: TextureRect = $Main/Current/Secondary/Image
		var cur_text: Label = $Main/Current/Secondary/Item
		
		image.texture = load(item.image)
		title.text = str(option)
		
		var pressed_select = func():
			current_secondary = str(option)
			cur_image.texture = load(item.image)
			cur_text.text = str(title.text)
			
		button.pressed.connect(pressed_select)
		
		current_slots = slots
	check_slots(current_slots, options.secondary_choices)
	for i in range(30,0,-1):
		var text = $Main/Time
		if i >= 10:
			text.text = "Time left to choose Items: 0:" + str(i)
			text.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		else:
			text.text = "Time left to choose Items: 0:0" + str(i)
			text.add_theme_color_override("font_color", Color(0.91, 0.309, 0.309, 1.0))
		await get_tree().create_timer(1,false,false,true).timeout
	hide()

func clear_slots(clear_primary: bool, clear_secondary: bool):
	if clear_primary:
		for i in primary.get_children():
			if i.name.contains("cloned slot"): i.queue_free()
	if clear_secondary:
		for i in secondary.get_children():
			if i.name.contains("cloned slot"): i.queue_free()
			
func check_slots(slots: Control, options_array: Array):
	for option in options_array:
		var count: Array = []
		for slot in slots.get_children():
			if slot.name.contains(str(option)): count.append(slot)
		if count.size() >= 2:
			for i in range(count.size()-1):
				var obj: Control = count[0]
				obj.queue_free()
				count.remove_at(0)
