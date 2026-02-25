extends Node

var settings = {}
var currency = 0
var items = []

var saved_items = false
var saved_currency = false
var loaded_items = false
var loaded_currency = false

func set_items(get_i = false):
	if not loaded_items: 
		saved_items = true
		return
	
	saved_items = false
	print("setting items: ", items)
	var res = await GDSync.account_document_set("items", {"items": items, "equipped": $"../Inv Handler".equipped_items})
	
	if res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("successfully set items.")
		if get_i:
			get_items()
	else:
		print("error setting items: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[res])
	saved_items = true

func get_items():
	print("getting items...")
	var res = await GDSync.account_get_document("items")
	var code = res["Code"]
	
	if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		print("got items: ", res["Result"].get("items", []))
		items = res["Result"].get("items", [])
		$"../Inv Handler".owned_items = items
		$"../Inv Handler".equipped_items = res["Result"].get("equipped", [])
		loaded_items = true
		if $"../Lobby/main/Panel/Locker".disabled:
			$"../Lobby/main/Panel/Locker".disabled = false
	elif code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
		print("items doesn't exist.")
		set_items(true)
	else:
		print("error getting items: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[code])
	
func set_currency(amount: int):
	if not loaded_currency:
		saved_currency = true
		return
	saved_currency = false
	print("setting currency of amount: ", amount)
	var res = await GDSync.account_document_set("currency", {"amount": amount})
	
	if res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("successfully set currency.")
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
		set_currency(0)
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
