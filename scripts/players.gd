extends Node3D

@export var player_scene : PackedScene

func _ready() -> void:
	GDSync.client_joined.connect(client_joined)
	GDSync.client_left.connect(client_left)

func client_joined(client_id : int) -> void:
	print("Client joined ", client_id)

	if client_id == GDSync.get_client_id():
		print("Own id ", client_id)

	var player = player_scene.instantiate()
	$"..".add_child(player)
	player.name = str(client_id)
	GDSync.set_gdsync_owner(player, client_id)

func client_left(client_id : int) -> void:
	print("Client left", client_id)
	
	var player : Node3D = get_node_or_null(str(client_id))
	if player != null:
		player.queue_free()
