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
	for i in range(5):
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
		slot.get_theme_stylebox("panel").bg_color = item.get_meta("slot_color")
		slot.get_theme_stylebox("panel").border_color = item.get_meta("slot_color").darkened(0.2)
		
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
			if item.get_meta("image") != "":
				pur_image.texture = load(str(item.get_meta("image")))
			if item.get_meta("purchased") == true:
				pur_button.hide()
			else:
				pur_button.show()
			current_id = item.get_meta("id")
			
		view.pressed.connect(pressed_view)

func _on_purchase_pressed() -> void:
	var item_price: int = str(price.text).replace("Price: ", "").replace(" Credits", "").to_int()
	if data.currency >= item_price:
		data.items.append(current_id)
		data.currency -= item_price
		data.set_items()
		data.set_currency(data.currency)
		for item in items.get_children():
			if item.get_meta("id") == current_id:
				item.set_meta("purchased", true)

func _on_exit_pressed() -> void:
	canvas.hide()
	
func _on_shop_pressed() -> void:
	refresh_shop()

func refresh_shop():
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
	elif code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
		set_shop()
	else:
		print("error getting shop: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[code])

func _on_reset_pressed() -> void:
	set_shop()

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
	var set_res = await GDSync.account_document_set("shop", {"items": shop_items, "can_refresh": false}, true)
	
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
