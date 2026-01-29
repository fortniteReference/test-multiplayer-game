extends Node

@onready var canvas = $CanvasLayer
@onready var waiting = $CanvasLayer/Waiting
@onready var looking = $"CanvasLayer/Looking for player"
@onready var voting = $CanvasLayer/Voting
@onready var task = $CanvasLayer/Waiting/Panel/task
# Called when the node enters the scene tree for the first time.

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
	
func _ready() -> void:
	GDSync.connected.connect(connected)
	GDSync.connection_failed.connect(connection_failed)
	
	GDSync.lobby_created.connect(lobby_created)
	GDSync.lobby_creation_failed.connect(lobby_creation_failed)
	GDSync.lobby_joined.connect(lobby_joined)
	GDSync.lobby_join_failed.connect(lobby_join_failed)

	GDSync.start_multiplayer()
	task.text = "connecting..."
	random_shi()

func connected() -> void:
	task.text = "connected!"
	GDSync.lobby_create("TestLobby")

func connection_failed(error : int) -> void:
	match(error):
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			task.text = "no public/private key matches what you entered."
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			task.text = "unable to connect. please check your internet and re-open the app."

func lobby_created(lobby_name : String) -> void:
	task.text = "creating lobby..."
	GDSync.lobby_join(lobby_name)

func lobby_creation_failed(lobby_name : String, error : int) -> void:
	task.text = "lobby creation failed."
	
	if error == ENUMS.LOBBY_CREATION_ERROR.LOBBY_ALREADY_EXISTS:
		task.text = "lobby creation failed. (err lobby exists)"
		GDSync.lobby_join(lobby_name)

func lobby_joined(lobby_name : String) -> void:
	task.text = "joining lobby " + lobby_name + "..."
	await get_tree().create_timer(1).timeout
	task.text = "ready to play!"
	await get_tree().create_timer(0.5).timeout
	get_tree().create_tween().tween_property(waiting, "position:y", 1500, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	looking.show()
	
	look_for_players()
	await get_tree().create_timer(2.1,false,false,true).timeout
	waiting.hide()

func look_for_players():
	var count = 0
	while count != 2:
		for child in get_children():
			if child is CharacterBody3D:
				count += 1
		if count == 2:
			break
		else:
			count = 0
		await get_tree().create_timer(0.5).timeout
	looking.get_node("Panel/Label").text = "Found Player! Loading..."
	await get_tree().create_timer(0.5).timeout
	get_tree().create_tween().tween_property(looking, "position:y", 1500, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(2).timeout
	# change the randi_range amount here to change available options
	if GDSync.is_host():
		voting.start_voting_call()
	voting.wait_add_items()
	if GDSync.is_host():
		GDSync.lobby_close()

func lobby_join_failed(lobby_name : String, _error):
	task.text = "the lobby " + lobby_name + " either doesn't exist, or has already began. Please try again later."
