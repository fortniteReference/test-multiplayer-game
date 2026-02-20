extends Panel

@onready var modes = $Modes
@onready var og_slot = $slot
@onready var container = $container/vbox

func create_slots():
	for slot in container.get_children():
		if slot != null: slot.queue_free()
	position.x = -575
	show()
	get_tree().create_tween().tween_property(self, "position:x", 0, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for mode: Node in modes.get_children():
		var mode_name = mode.get_meta("name")
		var mode_desc = mode.get_meta("description")
		var mode_tag = mode.get_meta("tag")
		var mode_enabled = mode.get_meta("enabled")
		var mode_limit = mode.get_meta("player_limit")
		
		var slot: Panel = og_slot.duplicate()
		container.add_child(slot)
		slot.show()
		
		var title: Label = slot.get_node("title")
		var desc: Label = slot.get_node("desc")
		var select: Button = slot.get_node("select")
		var not_enabled: Label = slot.get_node("not enabled")
		var splitter: Panel = slot.get_node("splitter")
		
		title.text = mode_name
		desc.text = mode_desc
		
		if mode_enabled == false:
			select.hide()
			select.disabled = true
			not_enabled.show()
			
		var select_pressed = func():
			$"../../..".find_lobby(mode_tag, mode_limit)
			get_tree().create_tween().tween_property(self, "position:x", -575, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			await get_tree().create_timer(0.75,false,false,true).timeout
			hide()
		var desc_size_changed = func():
			slot.custom_minimum_size.y = desc.size.y + 10
			splitter.size.y = desc.size.y - 10
		
		select.pressed.connect(select_pressed)
		desc.resized.connect(desc_size_changed)
	# -----------------------
	# Manual
	# -----------------------
	var last_slot = $"last slot".duplicate()
	container.add_child(last_slot)
	last_slot.show()
	
	var l_select: Button = last_slot.get_node("select tag")
	var find: Button = last_slot.get_node("join")
	var display: Panel = last_slot.get_node("manual mode")
	var vbox: VBoxContainer = display.get_node("scroll/vbox")
	var dis_button: Button = display.get_node("mode")
	
	var pressed_tag = func():
		for button in vbox.get_children():
			button.queue_free()
		display.show()
		for mode in modes.get_children():
			var button: Button = dis_button.duplicate()
			vbox.add_child(button)
			button.show()
			button.text = mode.get_meta("tag")
			
			var button_pressed = func():
				l_select.text = str(button.text)
				for child in vbox.get_children():
					child.queue_free()
				display.hide()
			button.pressed.connect(button_pressed)
	l_select.pressed.connect(pressed_tag)
