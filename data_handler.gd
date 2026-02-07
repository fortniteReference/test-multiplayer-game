extends Node

func set_settings(data: Dictionary):
	print("adding settings")
	var res = await GDSync.account_document_set("settings", data, false)
	
	if res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
		print("settings changed: ", data)
	else:
		print("settings did not change. Error: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[res])

func get_settings():
	print("retriving settings...")
	var response = await GDSync.account_get_document("settings")
	var res = response["Code"]
	
	if res == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		print("settings restored: ", response["Result"])
	else:
		print("settings did not restore. Error: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[res])
