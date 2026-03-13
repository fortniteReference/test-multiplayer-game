extends CanvasLayer

@onready var main = $main
@onready var container = $main/container/vbox
@onready var og_slot = $main/slot
@onready var gift_panel = $"main/gift panel"
@onready var title = $"main/gift panel/title"
@onready var desc = $"main/gift panel/desc"
@onready var your_currency = $"main/gift panel/your currency"
@onready var error_text = $"main/gift panel/error text"
@onready var image = $"main/gift panel/image"
@onready var purchase = $"main/gift panel/gift purchase"
@onready var back = $main/back
# ---------------------
@onready var final = $"main/final check"
@onready var final_desc = $"main/final check/panel/desc"
# ---------------------
@onready var items = $"../Items"
@onready var data = $"../../Data Handler"

var current_id = ""
var current_user = ""
var current_item = ""

var self_email = ""
var self_password = ""
var gifting = false
# Item info
var item_price = 0

func get_self_info():
	var res = await GDSync.account_get_document("user info")
	
	if res["Code"] == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS: pass
	else: print("error getting user info for self ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[res["Code"]])
	
	print("got self info")
	self_email = res["Result"]["email"]
	self_password = res["Result"]["password"]
	
func create_slots(id: String = ""):
	current_id = id
	
	title.text = ""
	desc.text = ""
	image.texture = null
	error_text.text = "Gifting User; This may take a moment.\nDo NOT close the app."
	error_text.hide()
	purchase.hide()
	
	show()
	get_self_info()
	for slot in container.get_children(): slot.queue_free()
	
	your_currency.text = "Your current balance is: " + str(data.currency) + " Credits"
	var friends_res = await GDSync.account_get_friends()
	var friends_code = friends_res["Code"]
	
	if friends_code == ENUMS.ACCOUNT_GET_FRIENDS_RESPONSE_CODE.SUCCESS:
		print("got friends")
		
		for friend in friends_res["Result"]:
			if friend["FriendStatus"] != 2: continue
			var username = friend["Username"]
			
			var slot: Panel = og_slot.duplicate()
			container.add_child(slot)
			slot.show()
			slot.set_meta("username", username)
			
			var slot_title: Label = slot.get_node("username")
			var slot_button: Button = slot.get_node("gift")
			
			slot_title.text = username
			
			var pressed_view = func():
				error_text.text = "Getting User info... Please wait."
				error_text.show()
				title.text = ""
				desc.text = ""
				image.texture = null
				purchase.hide()
				
				var res = await GDSync.account_get_external_document(username, "items")
				var code = res["Code"]
				
				if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
					var owned_items: Array = res["Result"]["items"]
					var gift_queue: Array = res["Result"].get("gift_queue", ["does not have"])
					
					if gift_queue.has("does not have"):
						error_text.text = "User's info is not up to date.\nMake sure they have the updated version, or wait until the log in again."
						return
					if owned_items.has(current_id) or gift_queue.has(current_id):
						error_text.text = "User owns this item already."
						return
					else: pass
				else:
					error_text.text = "Could not get user info, please try again later."
					print("error getting document for user: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[code])
					return

				error_text.text = "Gifting User; This may take a moment.\nDo NOT close the app."
				error_text.hide()
				var item: Node = null
				for item_node in items.get_children():
					if current_id == item_node.get_meta("id"): item = item_node
				if item != null:
					current_user = username
					current_item = item.get_meta("name")
					
					title.text = item.get_meta("name")
					desc.text = item.get_meta("description")
					
					if item.get_meta("image") != "":
						image.texture = load(str(item.get_meta("image")))
					item_price = item.get_meta("price")
					purchase.text = "Gift '" + item.get_meta("name") + "' to " + username
					purchase.show()
			slot_button.pressed.connect(pressed_view)
	else:
		print("did not get friends. error: ", ENUMS.ACCOUNT_GET_FRIENDS_RESPONSE_CODE.keys()[friends_code])

func _on_gift_purchase_pressed() -> void:
	final.show()
	final_desc.text = "You are about to give " + current_user + " the '" + current_item + "' item.\nAre you absolutely sure?\nIf you confirm, there is no going back."

func _on_back_pressed() -> void:
	hide()

func _on_no_pressed() -> void:
	final.hide()

func _on_confirm_pressed() -> void:
	if current_user == "": return
	
	title.text = ""
	desc.text = ""
	image.texture = null
	error_text.text = "Gifting User; This may take a moment.\nDo NOT close the app."
	error_text.show()
	purchase.hide()
	final.hide()
	
	if gifting:
		error_text.show()
		error_text.text = "Running Processes; Please try again later."
		await get_tree().create_timer(2).timeout
		error_text.hide()
		return
	gifting = true
	
	back.disabled = true
	for slot in container.get_children():
		var button: Button = slot.get_node("gift")
		button.disabled = true
	
	var gifted = false
	
	var info_res = await GDSync.account_get_external_document(current_user, "user info")
	var info_code = info_res["Code"]
	
	if info_code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS: pass
	else:
		error_text.text = "Failed to get user info, please retry.\nError: " + str(ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[info_code]) + "\nYour account has not been charged."
		back.disabled = false
		for slot in container.get_children():
			var button: Button = slot.get_node("gift")
			button.disabled = false
		gifting = false
		return

	var email = info_res["Result"]["email"]
	var password = info_res["Result"]["password"]
	
	var login_res = await GDSync.account_login(email, password, 60)
	var login_code = login_res["Code"]
	
	if login_code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
		print("logged into other user")
		var get_res = await GDSync.account_get_document("items")
		var get_code = get_res["Code"]
		
		if get_code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
			print("got docs")
			var owned_items: Array = get_res["Result"]["items"]
			var equipped_items: Array = get_res["Result"]["equipped"]
			var gift_queue: Array = get_res["Result"]["gift_queue"]
	
			if gift_queue.has(current_id): print("player already has item in gift queue")
			else: gift_queue.append(current_id)
	
			var set_res = await GDSync.account_document_set("items", {"items": owned_items, "equipped": equipped_items, "gift_queue": gift_queue}, true)
	
			if set_res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS: gifted = true
			else: error_text.text = "Failed to set user document: " + str(ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[set_res]) + ", please retry.\nYour account has not been charged."
		else: error_text.text = "Failed to get user document: " + str(ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[get_res["Code"]]) + ", please retry.\nYour account has not been charged."
	else: error_text.text = "Failed to login to user: " + str(ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.keys()[login_res["Code"]]) + ", please retry.\nYour account has not been charged."
	# ---------------------------------------------
	var reset_res = await GDSync.account_login(self_email, self_password, 86400)
	var reset_code = reset_res["Code"]
	
	if reset_code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
		if gifted:
			data.currency -= item_price
			if data.loaded_currency and data.loaded_items:
				data.set_currency(data.currency)
				data.set_items()
				while await get_tree().create_timer(0.1).timeout:
					if data.saved_currency and data.saved_items: break
			your_currency.text = "Your current balance is:" + str(data.currency) + " Credits"
			error_text.text = "Successfully gifted user!"
			await get_tree().create_timer(2,false,false,true).timeout
			error_text.hide()
	else:
		if gifted:
			error_text.text = "Error logging back into user account. User gifted successfully."
			data.currency -= item_price
			your_currency.text = "Your current balance is:" + str(data.currency) + " Credits"
		else: error_text.text = "Error logging back into user account.\nYour account has not been charged."
	
	back.disabled = false
	for slot in container.get_children():
		var button: Button = slot.get_node("gift")
		button.disabled = false
	await get_tree().create_timer(7).timeout
	gifting = false
