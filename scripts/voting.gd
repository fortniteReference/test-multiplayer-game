extends Control

@onready var main = $Main
@onready var world = $"../.."

@onready var local_votes = null
@onready var local_panel = null

var option_index = 0

var current_vote = ""
var current_panel = ""
var map_names = []
var options = {
	"Original": {"Items": ["pump", "thundersmg"], "Image": "", "Title": "Original", "Desc": "Nothing better than the og."}
	,"Random": {"Items": ["random"], "Image": "", "Title": "Random", "Desc": "ooh gambling!!!"}
	,"Snipers": {"Items": ["sniper"], "Image": "", "Title": "SNIPERS ONLY!!!", "Desc": "better have aim"}
	,"Custom": {"Items": ["custom"], "Image": "", "Title": "Choose Weapons", "Desc": "choose your own items from the available selection!"}
}

var index1 = 0
var index2 = 0
var index3 = 0

var min_option = 0 # Minimum RNG option for voting options
var max_option = 3 # Maximum RNG option for voting options

var player_name = ""
var items_to_add = []
var can_add_items = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GDSync.expose_func(start_voting)
	GDSync.expose_func(end_voting)
	GDSync.synced_event_triggered.connect(add_items)
	GDSync.player_data_changed.connect(change_vote)
	
func start_voting_call():
	GDSync.lobby_set_data("Indexes", [randi_range(min_option,max_option), randi_range(min_option,max_option), randi_range(min_option,max_option)])
	
	var indexes: Array = GDSync.lobby_get_data("Indexes", [])
	while indexes.is_empty():
		await GDSync.lobby_data_changed
		indexes = GDSync.lobby_get_data("Indexes", [])
		
	print("indexs: ", indexes[0], indexes[1], indexes[2])
	
	await get_tree().create_timer(1,false,false,true).timeout
	await GDSync.player_data_changed
	
	if GDSync.is_host():
		await get_tree().create_timer(2,false,false,true).timeout
		GDSync.call_func_all(start_voting)

func wait_add_items():
	var indexes = GDSync.lobby_get_data("Indexes", [])
	while indexes.is_empty():
		await GDSync.lobby_data_changed
		indexes = GDSync.lobby_get_data("Indexes", [])
		
	print("indexs: ", indexes[0], indexes[1], indexes[2])
	index1 = indexes[0]
	index2 = indexes[1]
	index3 = indexes[2]
	
	GDSync.player_set_data("Votes", ["", ""]) # first blank is current vote, second blank is current panel
	await GDSync.player_data_changed
	
	while not can_add_items:
		await get_tree().create_timer(0.01).timeout
		
	var player = world.get_node_or_null(str(GDSync.get_client_id()))
	if player:
		GDSync.synced_event_create(player.name, 0, [items_to_add])
		player.set_input_mode(true)

func start_voting():
	show()
	$"../Looking for player".hide()
	var player = world.get_node_or_null(str(GDSync.get_client_id()))
	print(player.name)
	if player:
		player.set_input_mode(false)
		player_name = str(GDSync.get_client_id())
	for panel in main.get_children():
		if not panel is Panel: continue
			
		var option = null
		if panel.name.contains("1"):
			option = options.values()[index1]
			panel.set_meta("key", index1)
		elif panel.name.contains("2"):
			option = options.values()[index2]
			panel.set_meta("key", index2)
		elif panel.name.contains("3"):
			option = options.values()[index3]
			panel.set_meta("key", index3)
		
		# -----------------------
		var image = panel.get_node("Image/image")
		var title = panel.get_node("Title")
		var desc = panel.get_node("Desc")
		var vote = panel.get_node("Vote")
		# -----------------------
		title.text = str(option.get("Title", "null"))
		desc.text = str(option.get("Desc", "null"))
		
		var get_image = str(option.get("Image", "null"))
		if get_image != "null" and get_image != "" and get_image.contains("res://"):
			image.texture = load(get_image)
			
		var pressed_vote = func():
			# GDSync.player_set_data("Votes", [str(options.keys()[panel.get_meta("key")]), panel.name])
			GDSync.player_set_data("Votes", [str(options.keys()[panel.get_meta("key")]), panel.name, current_panel])

		vote.pressed.connect(pressed_vote)
		
	var voting_time = main.get_node("VotingTime")
	voting_time.text = "Voting Ends in: 10"
	for i in range(10,0,-1):
		voting_time.text = "Voting Ends in: " + str(i)
		await get_tree().create_timer(1,false,false,true).timeout
	for panel in main.get_children():
		if not panel is Panel: continue
		panel.get_node("Vote").hide()
	GDSync.call_func_all(end_voting)
	
	
func change_vote(client_id, key, data):
	if key != "Votes" or not data is Array: return
	if data.size() == 0:
		print("no data, returned")
		return
	if (current_vote != "" and client_id == GDSync.get_client_id()) or client_id != GDSync.get_client_id():
		if client_id != GDSync.get_client_id() and data.size() == 3:
			var other_panel = main.get_node_or_null(str(data[2]))
			if other_panel:
				var other_votes = other_panel.get_node("Votes")
				var reset_votes = str(other_votes.text).to_int() - 1
				other_votes.text = str(reset_votes)
		else:
			var other_panel = main.get_node_or_null(str(current_panel))
			if other_panel:
				var other_votes = other_panel.get_node("Votes")
				var reset_votes = str(other_votes.text).to_int() - 1
				other_votes.text = str(reset_votes)
	var panel = main.get_node_or_null(str(data[1]))
	if panel:
		var votes = panel.get_node("Votes")
		var current_votes = str(votes.text).to_int() + 1
		votes.text = str(current_votes)
		if client_id == GDSync.get_client_id():
			current_vote = data[0]
			current_panel = panel.name
	
func end_voting():
	print("received")
	main.get_node("VotingTime").text = "Calculating all Votes..."
	await get_tree().create_timer(5,false,false,true).timeout
	var best_option = ""
	var ties = []
	var final_choice = ""
	# ------------------------
	var total_votes = {"Option1": {"Name": "", "Votes": 0}, "Option2": {"Name": "", "Votes": 0}, "Option3": {"Name": "", "Votes": 0}}
	var i = 1
	for panel in main.get_children():
		if not panel is Panel: continue
		
		var votes: Label = panel.get_node("Votes")
		var num_votes: int = str(votes.text).to_int()
		total_votes["Option" + str(i)]["Name"] = str(options.keys()[panel.get_meta("key")])
		total_votes["Option" + str(i)]["Votes"] = num_votes
		i += 1
	var no_votes = true
	for option in total_votes.values():
		if option["Votes"] != 0:
			no_votes = false
			break
	if no_votes:
		for option in total_votes.values():
			ties.append(option["Name"])
	else:
		var last_option = ""
		var last_votes = 0
		var current_votes = 0
		var current_option = ""
		for option in total_votes.values():
			current_votes = option["Votes"]
			current_option = option["Name"]
			if current_votes > last_votes:
				best_option = current_option
				ties = []
			elif current_votes == last_votes:
				if not ties.has(last_option):
					ties.append(last_option)
				if not ties.has(current_option):
					ties.append(current_option)
			# Before moving on
			last_option = current_option
			last_votes = current_votes
	
	if ties.size() > 1:
		final_choice = ties[randi_range(0,ties.size()-1)]
	else:
		final_choice = best_option
		
	var option = options[final_choice]
	var items = option.get("Items", null)
	
	var maps = $"../../Maps"
	for map in maps.get_children():
		map_names.append(str(map.name))
	if items[0] == "custom":
		var player = world.get_node_or_null(str(GDSync.get_client_id()))
		
		if player:
			var loot = player.get_node("CanvasLayer/Custom Loot")
			loot.start_custom()
			hide()
			await get_tree().create_timer(30,false,false,true).timeout
			
			var primary = loot.current_primary
			var secondary = loot.current_secondary
			if primary == "":
				primary = loot.get_node("Options").primary_choices[randi_range(0,-1)]
			if secondary == "":
				secondary = loot.get_node("Options").secondary_choices[randi_range(0,-1)]
			
			items_to_add = [primary, secondary]
			can_add_items = true
		else:
			await get_tree().create_timer(30,false,false,true).timeout
			items_to_add = ["pump", "pistol"]
			can_add_items = true
	else: 
		items_to_add = items
		can_add_items = true
		hide()
	
func add_items(name_player, params):
	if name_player != str(GDSync.get_client_id()) or not params[0] is Array: return
	
	print(params[0])
	if params[0].size() == 0:
		print("not enough items, returned")
		return
	
	var items = params[0]
	if items != null:
		var player = world.get_node_or_null(name_player)

		if items.has("random"):
			# for now, keep like this. later, make it change every round.
			print("mode is random")
			if player:
				var item_selection = []
				for i in range(2):
					# this way, players guarenteed will get a shotgun and spray weapon.
					item_selection = []
					print(i)
					if i == 0:
						for item in player.get_node("Camera3D").get_children():
							if item.name.contains("RayCast"): continue
							if item.shotgun == false: continue
					
							item_selection.append(item.name)
						print(item_selection)
						player.add_item(str(item_selection[randi_range(0,-1)]))
					else:
						for item in player.get_node("Camera3D").get_children():
							if item.name.contains("RayCast"): continue
							if item.shotgun == true: continue
					
							item_selection.append(item.name)
						print(item_selection)
						player.add_item(str(item_selection[randi_range(0,-1)]))
		else:
			if player:
				for item in items:
					player.add_item(str(item))
		if player and player.name == str(GDSync.get_client_id()):
			world.manage_game("start game")
