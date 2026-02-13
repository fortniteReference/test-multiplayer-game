extends Control

@onready var container = $"scroll/v contain"

var actions = {
	"forward": {"key": ""},
	"backward": {"key": ""},
	"left": {"key": ""},
	"right": {"key": ""},
	"reload": {"key": ""},
	"target": {"key": ""},
	"shoot": {"key": ""}
}

var default_actions = {
	"forward": {"key": "W"},
	"backward": {"key": "S"},
	"left": {"key": "A"},
	"right": {"key": "D"},
	"reload": {"key": "E"},
	"target": {"key": "Q"},
	"shoot": {"key": "mouse1"}
}

var cur_action = ""

func _input(u_event):
	if u_event is InputEventMouseButton and u_event.pressed and $"..".visible:
		set_key("mouse" + str(u_event.button_index))

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not $"..".visible: return
	
	set_key(event)

func set_key(event):
	for slot in container.get_children():
		if slot.get_meta("listening") == true:
			if event is String:
				if not event.contains("mouse"): return
				if event.contains("3"): return
				
				actions[cur_action]["key"] = event
				
				if event.contains("1"):
					slot.get_node("key").text = "Current Key: Left Click"
				elif event.contains("2"):
					slot.get_node("key").text = "Current Key: Right Click"
				slot.get_node("change").text = "Change"
				slot.set_meta("key", event)
				slot.set_meta("listening", false)
			else:
				var string_key = OS.get_keycode_string(event.keycode)
				actions[cur_action]["key"] = string_key
				
				slot.get_node("key").text = "Current Key: " + string_key
				slot.get_node("change").text = "Change"
				slot.set_meta("key", string_key)
				slot.set_meta("listening", false)

func delete_slots():
	for other_slot in container.get_children():
		other_slot.queue_free()

func create_slots():
	# ----------------------
	print("getting data")
	var response = await GDSync.account_get_document("controls")
	var code = response["Code"]
	
	if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		print("received data")
		actions = response["Result"]
	elif code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
		print("data doesn't exist, settingd data...")
		var res = await GDSync.account_document_set("controls", default_actions)
		
		if res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
			print("set data, returning for new.")
			await get_tree().create_timer(1).timeout
			create_slots()
			return
		else:
			print("did not set data. error: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[res])
	# ----------------------
	for action in actions:
		var og_slot: Panel = $slot
		var slot: Panel = og_slot.duplicate()
		container.add_child(slot)
		slot.name = "slot: " + str(action)
		slot.show()
		
		var act: Label = slot.get_node("action")
		var change: Button = slot.get_node("change")
		var key: Label = slot.get_node("key")
		
		var get_action = actions[action]
		var u_key = get_action.get("key", "")
		
		act.text = str(action.capitalize())
		key.text = "Current Key: " + str(u_key)
		if str(key.text).contains("mouse1"):
			key.text = "Current Key: Left Click"
		elif str(key.text).contains("mouse2"):
			key.text = "Current Key: Right Click"
		var pressed_change = func():
			for other_slot in container.get_children():
				other_slot.set_meta("listening", false)
				other_slot.get_node("change").text = "Change"
			change.text = "..."
			cur_action = str(action)
			slot.set_meta("listening", true)
			
		change.pressed.connect(pressed_change)

func save_controls():
	var res = await GDSync.account_document_set("controls", actions)
	
	if res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("data successfully saved: ", actions)
	else:
		print("data did not save. error: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[res])
	$"..".applied_controls = true
