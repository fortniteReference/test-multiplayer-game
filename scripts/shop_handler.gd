extends Node

@onready var items = $Items
@onready var canvas = $Canvas
@onready var og_slot = $Canvas/main/slot
@onready var container = $Canvas/main/container/grid
@onready var data = $"../Data Handler"
# ----------------------
@onready var purchase = $Canvas/main/purchase
@onready var pur_title = $Canvas/main/purchase/title
@onready var pur_desc = $Canvas/main/purchase/desc
@onready var pur_rarity = $Canvas/main/purchase/rarity
@onready var price = $Canvas/main/purchase/price
@onready var pur_image = $Canvas/main/purchase/image
@onready var pur_button = $Canvas/main/purchase/purchase

var current_email = ""
var current_pass = ""
var current_id = ""
var date_set = false
var changing_date = false
var testing_music = false

func select_items() -> Array:
	var selected_items = []
	#----------------
	var legendary = []
	var epic = []
	var rare = []
	var uncommon = []
	var common = []
	
	for item in items.get_children():
		if item.get_meta("enabled") == false: continue
		
		match item.get_meta("rarity"):
			"common":
				common.append(item.get_meta("id"))
			"uncommon":
				uncommon.append(item.get_meta("id"))
			"rare":
				rare.append(item.get_meta("id"))
			"epic":
				epic.append(item.get_meta("id"))
			"legendary":
				legendary.append(item.get_meta("id"))
	for i in range(9):
		var chance = randi_range(1,100)
		if chance == 1:
			selected_items.append(legendary[randi_range(0,legendary.size()-1)])
		elif chance > 1 and chance <= 5:
			selected_items.append(epic[randi_range(0,epic.size()-1)])
		elif chance > 5 and chance <= 20:
			selected_items.append(rare[randi_range(0,rare.size()-1)])
		elif chance > 20 and chance <= 50:
			selected_items.append(uncommon[randi_range(0,uncommon.size()-1)])
		else:
			selected_items.append(common[randi_range(0,common.size()-1)])
	return selected_items

func get_local_midnight_utc():
	# Get timezone info (returns a dict with "bias" in minutes)
	var tz_info = Time.get_time_zone_from_system()
	var bias_minutes = tz_info["bias"]
	
	# Convert bias to hours (e.g., -300 minutes = -5 hours)
	var bias_hours = bias_minutes / 60.0
	
	# Midnight UTC is 0. Local time is 0 + bias_hours.
	# We use fposmod to handle negative offsets (like -5 becoming 19:00)
	var local_hour = fposmod(bias_hours, 24)
	
	return local_hour

func create_slots(shop_items: Array):
	$Canvas/main/amount/amount.text = "You have " + str($"../Data Handler".currency) + " Credits."
	$Canvas/main/purchase.hide()
	pur_title.text = ""
	pur_desc.text = ""
	price.text = ""
	pur_rarity.text = ""
	pur_image.texture = null
	pur_button.hide()
	$Canvas/main/purchase.show()
	
	var prefix = "am"
	
	var hour = get_local_midnight_utc()
	if hour > 12:
		hour -= 12
		prefix = "pm"
	$"Canvas/main/time tip".text = "Tip: The Shop resets at midnight UTC Time. (" + str(hour).replace(".0", "") + ":00 " + prefix + " your local time)"
	
	for slot in container.get_children(): slot.queue_free()
	
	for shop_item in shop_items:
		var item: Node = null
		for item_node in items.get_children():
			if item_node.get_meta("id") == shop_item:
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
			pur_title.text = str(title.text)
			pur_desc.text = item.get_meta("description")
			pur_rarity.text = item.get_meta("rarity")
			pur_rarity.add_theme_color_override("font_color", item.get_meta("slot_color"))
			price.text = "Price: " + str(item.get_meta("price")) + " Credits"
			current_id = item.get_meta("id")
			if item.get_meta("image") != "":
				pur_image.texture = load(str(item.get_meta("image")))
			if $"../Inv Handler".owned_items.has(current_id):
				pur_button.hide()
			else:
				pur_button.show()
			if current_id.containsn("lobby_"):
				testing_music = true
				for music in $"../Shop Handler/Lobby Music".get_children():
					if music.playing: music.stop()
					
				var reference = item.get_meta("reference")
				var sound = item.get_node(reference)
				if sound and sound is AudioStreamPlayer: sound.play()
			elif testing_music:
				reset_to_lobby_music()
			
		view.pressed.connect(pressed_view)

func reset_to_lobby_music():
	testing_music = false
	for music in $"../Shop Handler/Lobby Music".get_children():
		if music.playing: music.stop()
				
	var music_id = ""
	for m_id in $"../Inv Handler".equipped_items:
		if not m_id.contains("lobby_"): continue
		music_id = m_id

	var music: Node = null
	for item_node in items.get_children():
		if item_node.get_meta("id").contains(str(music_id)):
			music = item_node
	if music != null:
		var reference = music.get_meta("reference")
		var sound = music.get_node(reference)
		if sound and sound is AudioStreamPlayer: sound.play()
		
func _on_purchase_pressed() -> void:
	if str(pur_button.text) != "Purchase": return
	
	var item_price: int = str(price.text).replace("Price: ", "").replace(" Credits", "").to_int()
	if data.currency >= item_price:
		pur_button.text = "Purchasing..."
		data.items.append(current_id)
		data.currency -= item_price
		data.set_items()
		data.set_currency(data.currency)
		$Canvas/main/amount/amount.text = "You have " + str(data.currency) + " credits."
		for item in items.get_children():
			if item.get_meta("id") == current_id:
				item.set_meta("purchased", true)
		pur_button.text = "Purchased!"
		await get_tree().create_timer(1.5).timeout
		pur_button.hide()
		pur_button.text = "Purchase"
	else:
		pur_button.text = "Not enough Credits"
		await get_tree().create_timer(1.5).timeout
		pur_button.text = "Purchase"

func _on_exit_pressed() -> void:
	canvas.hide()
	if testing_music:
		reset_to_lobby_music()
	
func _on_shop_pressed() -> void:
	refresh_shop()

func refresh_shop():
	for child in container.get_children(): child.queue_free()
	canvas.show()

	var res = await GDSync.account_get_external_document("shop_handler", "shop")
	var code = res["Code"]
	
	if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		print("successfully recieved shop")

		var result: Dictionary = res["Result"]
		# var can_refresh: bool = result.get("can_refresh", false)
		var shop_items: Array = result.get("items", [])
		
		if shop_items.size() == 0:
			print("no items in get shop, returned.")
			return
		
		create_slots(shop_items)
		check_date()
	elif code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
		set_shop()
	else:
		print("error getting shop: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[code])

func keep_checking_date():
	while canvas.visible:
		for i in range(120):
			await get_tree().create_timer(1).timeout
			if not canvas.visible: return
		check_date()
	
func check_date():
	if changing_date: return
	
	var res = await GDSync.account_get_external_document("shop_handler", "date")
	var code = res["Code"]
	
	if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		print("successfully recieved date")

		var refreshed = res["Result"]["refreshed"]
		var date: Dictionary = res["Result"]["date"]
		var today = Time.get_date_dict_from_system(true)
		var day = date["day"]
		
		if (day != today["day"]):
			refreshed = false
		
		if (day != today["day"]) and not refreshed:
			set_date()
			await get_tree().create_timer(0.5).timeout
			while not date_set: await get_tree().create_timer(0.05).timeout
			set_shop()
	elif code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
		set_date()
	else:
		print("error getting shop date: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[code])



func _on_reset_pressed() -> void:
	set_shop()

func set_date():
	for child in container.get_children(): child.queue_free()
	
	date_set = false
	changing_date = true
	var login_res = await GDSync.account_login("milokirsten@icloud.com", "20140971", 30)
	var login_code = login_res["Code"]

	if login_code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
		print("logged into shop to change date")
		pass
	else:
		print("couldn't log into shop to change date. error: ", ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.keys()[login_code])
		return

	var set_res = await GDSync.account_document_set("date", {"date": Time.get_date_dict_from_system(true), "refreshed": true}, true)
	
	if set_res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("set date, logging out.")
		var reset_res = await GDSync.account_login(current_email, current_pass, 86400)
		var reset_code = reset_res["Code"]
		
		if reset_code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
			print("re-logged in.")
			await get_tree().create_timer(7).timeout
		else:
			print("could not re-log in. error: ", ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.keys()[reset_code])
	else:
		print("error setting date: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[set_res])
	changing_date = false
	date_set = true
	
func set_shop():
	var shop_items = []
	
	shop_items = select_items()
	print(shop_items)
	var login_res = await GDSync.account_login("milokirsten@icloud.com", "20140971", 30)
	var login_code = login_res["Code"]

	if login_code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
		print("logged into shop")
		pass
	else:
		print("couldn't log into shop. error: ", ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.keys()[login_code])
		return

	var set_res = await GDSync.account_document_set("shop", {"items": shop_items, "refreshed": false}, true)
	
	if set_res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("set shop, logging out.")
		var reset_res = await GDSync.account_login(current_email, current_pass, 86400)
		var reset_code = reset_res["Code"]
		
		if reset_code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
			print("re-logged in.")
			refresh_shop()
		else:
			print("could not re-log in. error: ", ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.keys()[reset_code])
	else:
		print("error setting shop: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[set_res])

func get_reset_time() -> int:
	var now = Time.get_time_dict_from_system()
	var secs = (now.hour * 3600) + (now.minute * 60) + now.second
	return 86400 - secs
