extends Node3D

@export var player_scene : PackedScene

func _ready() -> void:
	GDSync.client_joined.connect(client_joined)
	GDSync.client_left.connect(client_left)

func client_joined(client_id : int) -> void:
	var player = player_scene.instantiate()
	$"..".add_child(player)
	player.name = str(client_id)
	GDSync.set_gdsync_owner(player, client_id)
	
	for user in get_parent().get_children():
		if user is CharacterBody3D: GDSync.synced_event_create(user.name, 0, ["change player acc", ""])

func client_left(client_id : int) -> void:
	var player = $"..".get_node_or_null(str(client_id))
	if player:
		player.queue_free()
	$"../CanvasLayer/Game/Score/YourScore/score".text = "9/10"
	$"..".manage_game("update scorewinner:" + str(GDSync.get_client_id()))
