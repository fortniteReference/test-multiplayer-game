extends Node

@onready var canvas = $CanvasLayer
@onready var waiting = $CanvasLayer/Waiting
@onready var looking = $"CanvasLayer/Looking for player"
@onready var voting = $CanvasLayer/Voting
@onready var task = $CanvasLayer/Waiting/Panel/task
@onready var try_again = $"CanvasLayer/Waiting/Panel/try again"
# Called when the node enters the scene tree for the first time.

var lobby_status = ""
var manual_status = ""
var score_debounce = false

var cooldown = 3

func random_shi():
	$AudioStreamPlayer.play()
	waiting.show()
	
	var pic = $"CanvasLayer/Waiting/Panel/random shi"
	var desc = $CanvasLayer/Waiting/Panel/desc1
	var options = ["res://random shi/lock.jpg", "res://random shi/pic 1.jpg",
	"res://random shi/pic 2.jpg", "res://random shi/pic 3.jpg"]
	
	var desc_options = ["who am i kidding bro i am not taking this seriously enough - milo",
	"i need vbuck plspsl (donations appreciated)", "you should reset character NOW! - someone",
	"fortnite clone yay", "guys am i cooked? - that one guy"]
	
	pic.texture = load(options[randi_range(0,(options.size() - 1))])
	desc.text = desc_options[randi_range(0,(desc_options.size() - 1))]
	
	await get_tree().create_timer(0.25,false,false,true).timeout
	get_tree().create_tween().tween_property(pic, "position:x", 15, 3)
	await get_tree().create_timer(3.35,false,false,true).timeout
	get_tree().create_tween().tween_property(pic, "rotation_degrees", 360, 2)
	
func _ready():
	get_tree().root.close_requested.connect(close_game)
	GDSync.connected.connect(connected)
	GDSync.connection_failed.connect(connection_failed)
	
	GDSync.lobbies_received.connect(lobbies_received)
	GDSync.lobby_created.connect(lobby_created)
	GDSync.lobby_creation_failed.connect(lobby_creation_failed)
	GDSync.lobby_joined.connect(lobby_joined)
	GDSync.lobby_join_failed.connect(lobby_join_failed)

	GDSync.start_multiplayer()
	task.text = "connecting..."
	random_shi()
	
func _on_try_again_pressed() -> void:
	try_again.hide()
	try_again.disabled = true
	GDSync.start_multiplayer()
	task.text = "connecting..."

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		close_game()
		
func close_game():
	GDSync.quit()

func connected() -> void:
	task.text = "connected!"
	await get_tree().create_timer(2,false,false,true).timeout
	
	task.text = "attempting to log in..."
	var response = await GDSync.account_login_from_session(86400)
	
	if response == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
		$Lobby.show()
	else:
		$"Account Handler/CanvasLayer/Login".show()
		waiting.hide()

var current_tag: String = ""
var current_limit: int = 0
var current_id: int = 0
func look_for_lobbies(tag, limit, id = 0):
	current_tag = tag
	current_limit = limit
	current_id = id
	GDSync.get_public_lobbies()
	
func lobbies_received(lobbies: Array):
	var manual_mode = false
	for lobby in lobbies:
		print(lobby)
		lobby_status = ""
		var lobby_name = str(lobby.get("Name", null))
		if lobby_name == null: continue
		# ----------------------------
		var start_pos = lobby_name.find("tag:") + 4
		var end_pos = lobby_name.find(", id:", start_pos) # Find end_key after start_pos
		var length = end_pos - start_pos
		var tag = lobby_name.substr(start_pos, length)
		print(tag)
		
		if current_id >= 100000:
			if not manual_mode: manual_mode = true
			if lobby_name.contains(str(current_id)):
				GDSync.lobby_join(lobby_name)
				manual_status = "trying"
				while manual_status == "trying":
					await get_tree().create_timer(0.01).timeout
				break
		if tag != current_tag:
			lobby_status = "join failed"
			continue
		# ----------------------------
		GDSync.lobby_join(lobby_name)
		while lobby_status == "":
			await get_tree().create_timer(0.01).timeout
		if lobby_status == "joined":
			break
		else:
			continue
	if lobby_status == "join failed" or lobbies.size() == 0:
		GDSync.lobby_create("lobby, tag:" + current_tag + ", id:" + str(randi_range(100000,999999)), "", true, current_limit)
		print("created lobby")
	$"Data Handler".get_settings()
	$Lobby.found_lobby = true

func connection_failed(error : int) -> void:
	match(error):
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			task.text = "connection timeout; please check your internet."
			try_again.show()
			try_again.disabled = false

func lobby_created(lobby_name : String) -> void:
	task.text = "creating lobby..."
	GDSync.lobby_join(lobby_name)

func lobby_creation_failed(lobby_name : String, error : int) -> void:
	task.text = "lobby creation failed."
	
	if error == ENUMS.LOBBY_CREATION_ERROR.LOBBY_ALREADY_EXISTS:
		task.text = "lobby creation failed. (err lobby exists)"
		GDSync.lobby_join(lobby_name)

func lobby_joined(_lobby_name : String) -> void:
	lobby_status = "joined"
	await get_tree().create_timer(0.5).timeout
	get_tree().create_tween().tween_property(waiting, "position:y", 1500, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	looking.show()
	
	current_limit = GDSync.lobby_get_player_limit()
	look_for_players()
	await get_tree().create_timer(2.1,false,false,true).timeout
	waiting.hide()
	$Lobby.hide()
	if $"Friend Handler/CanvasLayer".visible:
		$"Friend Handler/CanvasLayer".hide()

func look_for_players():
	var count = 0
	# ---------------------------
	var lobby_name = GDSync.lobby_get_name()
	var start_pos = lobby_name.find(", id:") + 5
	var id = lobby_name.substr(start_pos, 6)
	# ---------------------------
	looking.get_node("Panel/id").text = "Lobby ID: " + id
	looking.get_node("Panel/tag").text = "Lobby Type: " + current_tag
	while count != current_limit:
		for child in get_children():
			if child is CharacterBody3D:
				count += 1
		if count == current_limit:
			break
		else:
			count = 0
		await get_tree().create_timer(0.5).timeout
	looking.get_node("Panel/Label").text = "Found Player! Loading..."
	await get_tree().create_timer(2).timeout
	looking.get_node("Panel/Label").text = "Waiting for launcher to verify..."

	if GDSync.is_host():
		voting.start_voting_call()
	voting.wait_add_items()
	if GDSync.is_host():
		GDSync.lobby_close()
		
func manage_game(command: String):
	# --------------------------
	# Objects
	var player = get_node_or_null(str(GDSync.get_client_id()))
	var barrier = $Barrier
	var spawn1 = $PlayerSpawn1
	var spawn2 = $PlayerSpawn2
	# --------------------------
	# Game
	var game = $CanvasLayer/Game
	var barrier_panel = $CanvasLayer/Game/BarrierDrop
	var barrier_timer = $CanvasLayer/Game/BarrierDrop/timer
	# --------------------------
	if player:
		if command == "start game" or command == "reset map":
			if command == "start game":
				game.show()
				$CanvasLayer/Game/Score/YourScore/score.text = "0/10"
				$CanvasLayer/Game/Score/EnemyScore/score.text = "0/10"
			barrier.show()
			barrier.get_node("CollisionShape3D").disabled = false
			barrier_panel.show()
			get_tree().create_tween().tween_property(barrier_panel, "position:y", 15, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			if GDSync.is_host():
				player.position = spawn1.position
			else:
				player.position = spawn2.position
			barrier_timer.text = "3"
			for i in range(3,0,-1):
				await get_tree().create_timer(1,false,false,true).timeout
				barrier_timer.text = str(i)
			await get_tree().create_timer(1,false,false,true).timeout
			barrier_timer.text = "0"
			barrier.hide()
			barrier.get_node("CollisionShape3D").disabled = true
			get_tree().create_tween().tween_property(barrier_panel, "position:y", -126, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		elif command.contains("update score") and not score_debounce:
			score_debounce = true
			var string1 = str(command.replace("update score", ""))
			var pos1 = string1.find("winner:")
			var pos2 = string1.find("loser:")
			var winner = string1.substr(pos1 + "winner:".length(), 6)
			var loser = string1.substr(pos2 + "loser:".length(), 6)
			
			var score_text = $CanvasLayer/Game/Score/YourScore/score
			var enemy_text = $CanvasLayer/Game/Score/EnemyScore/score
			if winner.to_int() == GDSync.get_client_id():
				var amount_of_wins = str(str(score_text.text).replace("/10", "")).to_int() + 1
				score_text.text = str(amount_of_wins) + "/10"
			elif loser.to_int() == GDSync.get_client_id():
				var amount_of_wins = str(str(enemy_text.text).replace("/10", "")).to_int() + 1
				enemy_text.text = str(amount_of_wins) + "/10"
				
			await get_tree().create_timer(cooldown).timeout
			score_debounce = false
			
func check_for_leave():
	var amount_of_players = 0
	for child in get_children():
		if child is CharacterBody3D:
			amount_of_players += 1

	if amount_of_players != 1: return
	cooldown = 0.01
	
	var score_text = $CanvasLayer/Game/Score/YourScore/score
	score_text.text = "10/10"
	
	var player = get_node_or_null(str(GDSync.get_client_id()))
	if player: player.set_input_mode(false)
	
	GDSync.lobby_leave()
	$CanvasLayer/Game/WinScreen.position = Vector2.ZERO
	$CanvasLayer/Game/WinScreen.hide()
	$CanvasLayer.show()
	$CanvasLayer/Game.hide()
	$Lobby.show()

func lobby_join_failed(lobby_name : String, _error):
	lobby_status = "join failed"
	task.add_theme_font_size_override("font_size", 18)
	task.text = "the lobby " + lobby_name + " either doesn't exist, or has already began. Please try again later."

func _on_lobby_pressed() -> void:
	var lose = $CanvasLayer/Game/LoseScreen
	var win = $CanvasLayer/Game/WinScreen
	
	lose.hide()
	win.hide()
	$Lobby.show()
	$Lobby/main/Panel/Play.disabled = false
