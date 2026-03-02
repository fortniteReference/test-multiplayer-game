extends Node

var settings = {}
var currency = 0
var items = []
var gift_queue = []

var saved_items = false
var saved_currency = false
var loaded_items = false
var loaded_currency = false

func set_items(code = ""):
	if not loaded_items and not code.containsn("add items"): 
		saved_items = true
		return
	
	saved_items = false
	print("setting items: ", items)
	var res = await GDSync.account_document_set("items", {"items": items, "equipped": $"../Inv Handler".equipped_items, "gift_queue": gift_queue}, true)
	
	if res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("successfully set items.")
		if code.containsn("get items"):
			get_items()
	else:
		print("error setting items: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[res])
	saved_items = true

func get_items(h_code = ""):
	print("getting items...")
	var res = await GDSync.account_get_document("items")
	var code = res["Code"]
	
	if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		print("got items: ", res["Result"].get("items", []))
		items = res["Result"].get("items", [])
		$"../Inv Handler".owned_items = items
		$"../Inv Handler".equipped_items = res["Result"].get("equipped", [])
		gift_queue = res["Result"].get("gift_queue", [])
		
		loaded_items = true
		if $"../Lobby/main/Panel/Locker".disabled:
			$"../Lobby/main/Panel/Locker".disabled = false
		if h_code.containsn("play lobby"):
			$"../Inv Handler".play_lobby_music()
		if h_code.containsn("check gifts"):
			var gift_panel = $"../Lobby/main/Panel/gift panel"
			var container = $"../Lobby/main/Panel/gift panel/container/hbox"
			var claim: Button = $"../Lobby/main/Panel/gift panel/claim"
			var og_slot = $"../Lobby/main/Panel/gift panel/slot"
			
			for child in container.get_children():
				child.queue_free()
			var queue: Array = gift_queue
			if queue.size() > 0:
				gift_panel.show()
				for item_id in queue:
					var item: Node = null
					for item_node in $"../Shop Handler/Items".get_children():
						if item_node.get_meta("id").contains(str(item_id)):
							item = item_node
					if item == null: continue
					
					var slot = og_slot.duplicate()
					container.add_child(slot)
					slot.show()
					slot.get_node("title").text = item.get_meta("name")
					
					if item.get_meta("image") != "":
						slot.get_node("image").texture = load(str(item.get_meta("image")))
				var claim_pressed = func():
					gift_panel.hide()
					
					$"../Inv Handler".owned_items.append_array(gift_queue)
					gift_queue = []
				if not claim.pressed.is_connected(claim_pressed):
					claim.pressed.connect(claim_pressed)
			else:
				gift_panel.hide()
	elif code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
		print("items doesn't exist.")
		set_items("add items, get items")
	else:
		print("error getting items: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[code])

func set_currency(amount: int):
	if not loaded_currency and amount != -1:
		saved_currency = true
		return
	saved_currency = false
	print("setting currency of amount: ", amount)
	var final = 0
	if amount == -1:
		final = 0
	else:
		final = amount
	var res = await GDSync.account_document_set("currency", {"amount": final})
	
	if res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("successfully set currency of amount: ", final)
		if amount == -1:
			get_currency()
	else:
		print("error setting currency: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[res])
	saved_currency = true

func get_currency():
	print("getting currency...")
	var res = await GDSync.account_get_document("currency")
	var code = res["Code"]
	
	if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		print("got currency: ", res["Result"].get("amount", 0))
		currency = res["Result"].get("amount", 0)
		loaded_currency = true
	elif code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
		print("currency doesn't exist.")
		set_currency(-1) # -1 will add the currency document
	else:
		print("error getting currency: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[code])

func set_settings(data: Dictionary, get_data = false):
	print("adding settings")
	var res = await GDSync.account_document_set("settings", data, false)
	
	if res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("settings changed: ", data)
		if get_data:
			await get_tree().create_timer(1).timeout
			get_settings()
	else:
		print("settings did not change. Error: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[res])
	$"../Lobby/main/Panel/Menu/Settings".applied_aim = true

func get_settings():
	print("retriving settings...")
	var response = await GDSync.account_get_document("settings")
	var res = response["Code"]
	
	if res == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		print("settings restored: ", response["Result"])
	else:
		print("settings did not restore. Error: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[res])
		if res == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
			set_settings({"aim_sens": 0.001, "hip_sens": 0.005}, true)
	settings = response["Result"]
