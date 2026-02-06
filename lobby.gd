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
	play.disabled = true
	world.look_for_lobbies()
	
	play_label.show()
	play_label.text = "Finding Lobby...\nTime Elapsed: 0:00"
	
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
	pass # Replace with function body.

func _on_back_pressed() -> void:
	pass # Replace with function body.

func _on_logout_pressed() -> void:
	pass # Replace with function body.
