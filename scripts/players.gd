extends Node3D

@export var player_scene : PackedScene

func _ready() -> void:
	GDSync.client_joined.connect(client_joined)
	GDSync.client_left.connect(client_left)
	$"..".child_exiting_tree.connect(player_left)

func client_joined(client_id : int) -> void:
	var player = player_scene.instantiate()
	$"..".add_child(player)
	player.name = str(client_id)
	GDSync.set_gdsync_owner(player, client_id)
	
	for plr in get_parent().get_children():
		if plr is CharacterBody3D: plr.get_player_equipped_items()

func client_left(client_id : int) -> void:
	var player = $"..".get_node_or_null(str(client_id))
	if player:
		player.queue_free()

func player_left(node: Node):
	if not node is CharacterBody3D: return
	$"..".check_for_leave("player left")
