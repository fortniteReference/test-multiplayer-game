extends Node

@onready var friend_gui = $"CanvasLayer/friend gui"
@onready var request_gui = $"CanvasLayer/request gui"
@onready var friend_slot = $"CanvasLayer/friend gui/slot"
@onready var request_slot = $"CanvasLayer/request gui/slot"
@onready var f_container = $"CanvasLayer/friend gui/container"
@onready var r_container = $"CanvasLayer/request gui/container"

func get_friends():
	var response = await GDSync.account_get_friends()
	var code = response["Code"]
	
	if code == ENUMS.ACCOUNT_GET_FRIENDS_RESPONSE_CODE.SUCCESS:
		for dict in code["Result"]:
			if not dict.has("Lobby"): continue
			
			var user = dict.get("Username", "")
			if user == "": continue
			
			var lobby_dict: Dictionary = dict.get("Lobby", "")
			var lobby = lobby_dict.get("Name", "")
			
			var slot: Panel = friend_slot.duplicate()
			f_container.add_child(slot)
			slot.get_node("title").text = str(user)
			slot.name = "slot for: " + str(user)
			slot.show()
			
			var join_button: Button = slot.get_node("join")
			var remove_button: Button = slot.get_node("remove")
			var status: Label = slot.get_node("status")
			
			if lobby == "":
				join_button.hide()
				join_button.disabled = true
				status.text = "Status: Offline"
			else:
				status.text = "Status: Online"
				
			var join_friend = func():
				join_button.disabled = true
				GDSync.lobby_join(str(lobby))
				await get_tree().create_timer(5,false,false,true).timeout
				join_button.disabled = false
			var remove_friend = func():
				var res = await GDSync.account_remove_friend(str(user))
				
				if res == ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.SUCCESS:
					slot.queue_free()
					print("removed friend: ", user)
				else:
					print("did not remove friend. error: ", ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.keys()[res])
			
			join_button.pressed.connect(join_friend)
			remove_button.pressed.connect(remove_friend)
			
func get_friend_requests():
	var response = await GDSync.account_get_friends()
	var code = response["Code"]
	
	if code == ENUMS.ACCOUNT_GET_FRIENDS_RESPONSE_CODE.SUCCESS:
		for dict in code["Result"]:
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
			var decline_button: Button = slot.get_node("accept")
			var accept = func():
				accept_button.disabled = true
				var res = await GDSync.account_accept_friend_request(str(user))
				
				if res == ENUMS.ACCOUNT_ACCEPT_FRIEND_REQUEST_RESPONSE_CODE.SUCCESS:
					slot.queue_free()
					print("accepted friend: ", user)
				else:
					print("did not accept friend. error: ", ENUMS.ACCOUNT_ACCEPT_FRIEND_REQUEST_RESPONSE_CODE.keys()[res])
				if slot != null: accept_button.disabled = false
			var decline = func():
				var res = await GDSync.account_remove_friend(str(user))
				
				if res == ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.SUCCESS:
					slot.queue_free()
					print("successfully removed request for: ", user)
				else:
					print("did not remove friend. error: ", ENUMS.ACCOUNT_REMOVE_FRIEND_RESPONSE_CODE.keys()[res])
				if slot != null: decline_button.disabled = false
			
			accept_button.pressed.connect(accept)
			decline_button.pressed.connect(decline)
