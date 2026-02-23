extends CanvasLayer

@onready var world = $".."

@onready var main = $main
@onready var panel = $main/Panel
@onready var play = $main/Panel/Play
@onready var play_label = $main/Panel/Play/Label
@onready var menu = $main/Panel/Menu
@onready var back = $main/Panel/Menu/back
@onready var logout = $main/Panel/Menu/logout

var found_lobby = false

func _on_play_pressed() -> void:
	$"main/Panel/Mode Selection".create_slots()
	play.disabled = true
	$"../Friend Handler/CanvasLayer".hide()
	$"../Friend Handler/CanvasLayer/friend gui".hide()
	$"../Friend Handler/CanvasLayer/request gui".hide()
	$main/Panel/MenuButton/Menu.hide()
	$main/Panel/Friends.hide()
	
func _on_exit_pressed() -> void:
	exit_selection()

func exit_selection(enable_play = true):
	get_tree().create_tween().tween_property($"main/Panel/Mode Selection", "position:x", -575, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.75,false,false,true).timeout
	if enable_play:
		$main/Panel/MenuButton/Menu.show()
		$main/Panel/Friends.show()
		play.disabled = false
	
func find_lobby(tag: String, limit: int, id = 0):
	world.look_for_lobbies(tag, limit, id)
	
	play_label.show()
	play_label.text = "Finding a " + tag + " Lobby...\nTime Elapsed: 0:00"
	
	var sec = 0
	var mins = 0

	found_lobby = false
	while not found_lobby:
		sec += 1
		if sec % 60 == 0:
			mins += 1
			sec = 0
		if sec < 10:
			play_label.text = "Finding Lobby...\nTime Elapsed: " + str(mins) + ":0" + str(sec)
		else:
			play_label.text = "Finding Lobby...\nTime Elapsed: " + str(mins) + ":" + str(sec)
		for i in range(20):
			if found_lobby:
				break
			await get_tree().create_timer(0.05,false,false,true).timeout
	play_label.text = "Found Lobby! Loading..."
	await get_tree().create_timer(2,false,false,true).timeout
	hide()

func _on_menu_pressed() -> void:
	menu.show()
	$main/Panel/Friends.hide()
	$"../Friend Handler/CanvasLayer".hide()
	$"../Friend Handler/CanvasLayer/friend gui".hide()
	$"../Friend Handler/CanvasLayer/request gui".hide()

func _on_back_pressed() -> void:
	menu.hide()
	$main/Panel/Friends.show()

func _on_logout_pressed() -> void:
	logout.text = "Logging Out..."
	var res = await GDSync.account_logout()
	
	if res == ENUMS.ACCOUNT_LOGOUT_RESPONSE_CODE.SUCCESS:
		var canvas = get_node("../Account Handler/CanvasLayer")
		var login = get_node("../Account Handler/CanvasLayer/Login")
		canvas.show()
		login.show()
		$"../CanvasLayer/Waiting".hide()
		menu.hide()
		hide()
	else:
		logout.text = "Failed to Logout."
		print("couldn't log out. error: ", ENUMS.ACCOUNT_LOGOUT_RESPONSE_CODE.keys()[res])
		await get_tree().create_timer(2,false,false,true).timeout
		logout.text = "Logout"
		
