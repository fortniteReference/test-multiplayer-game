extends Node

var settings = {}

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
