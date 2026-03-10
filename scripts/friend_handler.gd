extends Node

@onready var canvas = $CanvasLayer
@onready var friend_gui = $"CanvasLayer/friend gui"
@onready var request_gui = $"CanvasLayer/request gui"
@onready var friend_slot = $"CanvasLayer/friend gui/slot"
@onready var request_slot = $"CanvasLayer/request gui/slot"
@onready var f_container = $"CanvasLayer/friend gui/ScrollContainer/container"
@onready var r_container = $"CanvasLayer/request gui/ScrollContainer/container"
@onready var f_loading = $"CanvasLayer/friend gui/loading"
@onready var r_loading = $"CanvasLayer/request gui/loading"
# Buttons
@onready var back = $"CanvasLayer/friend gui/back"
@onready var friend_reqs = $"CanvasLayer/friend gui/friend reqs"
@onready var req_gui_back = $"CanvasLayer/request gui/request gui back"
@onready var add = $"CanvasLayer/request gui/Add"

func get_friends():
	clear_container(f_container)
	$"../Lobby/main/Panel/MenuButton".hide()
	$"CanvasLayer/friend gui/back".disabled = true
	f_loading.play()
	f_loading.show()
	
	back.disabled = true
	friend_reqs.disabled = true
	
	var response = await GDSync.account_get_friends()
	var code = response["Code"]
	
	back.disabled = false
	friend_reqs.disabled = false
	if code == ENUMS.ACCOUNT_GET_FRIENDS_RESPONSE_CODE.SUCCESS:
		var online = {}
		var other = {}
		var i = 0
		
		f_loading.stop()
		f_loading.hide()
		for dict in response["Result"]:
			if not dict.has("Lobby"): continue
			
			var user = dict.get("Username", "")
			if user == "": continue
			
			var lobby_dict: Dictionary = dict.get("Lobby", "")
			var lobby = lobby_dict.get("Name", "")
			
			var slot: Panel = friend_slot.duplicate()
			var string = "slot" + str(i)
			if lobby == "":
				other[string] = {}
				other[string]["slot"] = slot
				other[string]["user"] = user
			else:
				online[string] = {}
				online[string]["slot"] = slot
				online[string]["user"] = user
				online[string]["lobby"] = lobby
			print(online)
			print(other)
			i += 1
		
		var text1 = $"CanvasLayer/friend gui/online copy".duplicate()
		f_container.add_child(text1)
		text1.show()
		if online.size() == 0: text1.queue_free()
		for slot_dict in online:
			var user = online[slot_dict]["user"]
			var slot = online[slot_dict]["slot"]
			var lobby = online[slot_dict]["lobby"]
			
			f_container.add_child(slot)
			slot.get_node("title").text = str(user)
			slot.name = "slot for: " + str(user)
			slot.show()
			
			var join_button: Button = slot.get_node("join")
			var remove_button: Button = slot.get_node("remove")
			var status: Label = slot.get_node("status")
			
			join_button.show()
			status.text = "Status: Online"
				
			var join_friend = func():
				join_button.disabled = true
				GDSync.lobby_join(str(lobby))
				await get_tree().create_timer(5,false,false,true).timeout
				join_button.disabled = false
			var remove_friend = func():
				var res = await GDSync.account_remove_friend(str(user))
				
				if res == ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.SUCCESS:
					if slot != null:
						slot.queue_free()
					print("removed friend: ", user)
				else:
					print("did not remove friend. error: ", ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.keys()[res])
			
			join_button.pressed.connect(join_friend)
			remove_button.pressed.connect(remove_friend)
		# -------------------------------------
		var text2 = $"CanvasLayer/friend gui/offline copy".duplicate()
		f_container.add_child(text2)
		text2.show()
		if other.size() == 0: text2.queue_free()
		for slot_dict in other:
			var user = other[slot_dict]["user"]
			var slot = other[slot_dict]["slot"]
			
			f_container.add_child(slot)
			slot.get_node("title").text = str(user)
			slot.name = "slot for: " + str(user)
			slot.show()
			
			var join_button: Button = slot.get_node("join")
			var remove_button: Button = slot.get_node("remove")
			var status: Label = slot.get_node("status")
			
			join_button.hide()
			status.text = "Status: Offline"
			
			var remove_friend = func():
				var res = await GDSync.account_remove_friend(str(user))
				
				if res == ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.SUCCESS:
					if slot != null:
						slot.queue_free()
					print("removed friend: ", user)
				else:
					print("did not remove friend. error: ", ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.keys()[res])
			
			remove_button.pressed.connect(remove_friend)

func get_friend_requests():
	clear_container(r_container)
	
	add.disabled = true
	req_gui_back.disabled = true
	r_loading.play()
	r_loading.show()
	
	var response = await GDSync.account_get_friends()
	var code = response["Code"]
	
	add.disabled = false
	req_gui_back.disabled = false
	r_loading.stop()
	r_loading.hide()
	if code == ENUMS.ACCOUNT_GET_FRIENDS_RESPONSE_CODE.SUCCESS:
		for dict in response["Result"]:
			if dict.has("Lobby"): continue
			
			var user = dict.get("Username", "")
			if user == "":
				print("continued")
				continue
			
			var slot: Panel = request_slot.duplicate()
			r_container.add_child(slot)
			slot.get_node("title").text = str(user)
			slot.name = "slot for: " + str(user)
			slot.show()
			
			var accept_button: Button = slot.get_node("accept")
			var decline_button: Button = slot.get_node("decline")
			var accept = func():
				accept_button.disabled = true
				slot.get_node("desc").text = "Accepting..."
				var res = await GDSync.account_accept_friend_request(str(user))
				
				if res == ENUMS.ACCOUNT_ACCEPT_FRIEND_REQUEST_RESPONSE_CODE.SUCCESS:
					if slot != null:
						slot.get_node("desc").text = "Accepted!"
						await get_tree().create_timer(2,false,false,true).timeout
						slot.queue_free()
				else:
					if slot != null:
						slot.get_node("desc").text = "Error Accepting: " + str(ENUMS.ACCOUNT_ACCEPT_FRIEND_REQUEST_RESPONSE_CODE.keys()[res])
						await get_tree().create_timer(2,false,false,true).timeout
						slot.get_node("desc").text = "sent you a friend request!"
				if slot != null: accept_button.disabled = false
			var decline = func():
				slot.get_node("desc").text = "Declining..."
				var res = await GDSync.account_remove_friend(str(user))
				
				if res == ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.SUCCESS:
					slot.queue_free()
					print("successfully removed request for: ", user)
				else:
					print("did not remove friend. error: ", ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.keys()[res])
				if slot != null: decline_button.disabled = false
			
			accept_button.pressed.connect(accept)
			decline_button.pressed.connect(decline)

func clear_container(container: Control):
	for child in container.get_children():
		child.queue_free()

func _on_back_pressed() -> void:
	canvas.hide()
	$"../Lobby/main/Panel/MenuButton".show()

func _on_friend_reqs_pressed() -> void:
	get_friend_requests()
	friend_gui.hide()
	request_gui.show()

func _on_request_gui_back_pressed() -> void:
	get_friends()
	friend_gui.show()
	request_gui.hide()

func _on_friends_pressed() -> void:
	canvas.show()
	friend_gui.show()
	request_gui.hide()
	get_friends()

func _on_add_pressed() -> void:
	var search = $"CanvasLayer/request gui/Search"
	var user_to_find = str(search.text)
	
	search.text = "Sending..."
	var response = await GDSync.account_send_friend_request(user_to_find)
	
	if response == ENUMS.ACCOUNT_SEND_FRIEND_REQUEST_RESPONSE_CODE.SUCCESS:
		search.text = "Sent Request!"
		await get_tree().create_timer(2,false,false,true).timeout
		search.text = ""
	elif response == ENUMS.ACCOUNT_SEND_FRIEND_REQUEST_RESPONSE_CODE.USER_DOESNT_EXIST:
		search.text = "User doesn't exist."
		await get_tree().create_timer(2,false,false,true).timeout
		search.text = ""
	elif response == ENUMS.ACCOUNT_SEND_FRIEND_REQUEST_RESPONSE_CODE.FRIEND_ALREADY_ADDED:
		search.text = "Already friends with user."
		await get_tree().create_timer(2,false,false,true).timeout
		search.text = ""
	else:
		search.text = "Error adding user."
		await get_tree().create_timer(2,false,false,true).timeout
		search.text = ""
