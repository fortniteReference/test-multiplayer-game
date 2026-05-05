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
	,"Snipers": {"Items": ["random", "sniper", "impactsniper"], "Image": "", "Title": "SNIPERS ONLY!!!", "Desc": "better have aim"}
	,"Custom": {"Items": ["custom"], "Image": "", "Title": "Choose Weapons", "Desc": "choose your own items from the available selection!"}
}

var min_option = 0 # Minimum RNG option for voting options
var max_option = 3 # Maximum RNG option for voting options

var items_to_add = []
var can_add_items = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# GDSync.expose_func(start_voting)
	# GDSync.expose_func(end_voting)
	GDSync.synced_event_triggered.connect(add_items)
	GDSync.synced_event_triggered.connect(get_voting_options)
	GDSync.synced_event_triggered.connect(change_vote)
	# GDSync.player_data_changed.connect(change_vote)

func set_voting_options():
	if not GDSync.is_host(): return
	
	var all_options = range(options.size())
	var indexes = []
	for i in range(3):
		var chosen = randi_range(min_option,max_option)
		if all_options.has(chosen) and min_option == 0 and max_option == options.size()-1:
			indexes.append(chosen)
			all_options.erase(chosen)
		else:
			indexes.append(chosen)
	GDSync.synced_event_create("set votes", 1, [indexes])
	
func get_voting_options(event_name: String, params: Array):
	if event_name != "set votes": return
	if not params[0] is Array: return
	
	can_add_items = false
	var indexes = params[0]
	
	show()
	$"../Looking for player".hide()
	var player = world.get_node_or_null(str(GDSync.get_client_id()))
	if player:
		player.set_input_mode(false)
	for panel in main.get_children():
		if not panel is Panel: continue
		panel.get_node("Vote").show()

	for panel in main.get_children():
		if not panel is Panel: continue
		
		var num = indexes[str(panel.name).replace("Voting", "").to_int()-1]
		var option = options.values()[num]
		
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
			GDSync.synced_event_create(player.name + "changes vote", 0, [current_panel, str(panel.name)])

		vote.pressed.connect(pressed_vote)
		
	var voting_time = main.get_node("VotingTime")
	voting_time.text = "Voting Ends in: 10"
	for i in range(10,0,-1):
		voting_time.text = "Voting Ends in: " + str(i)
		await get_tree().create_timer(1,false,false,true).timeout
	for panel in main.get_children():
		if not panel is Panel: continue
		panel.get_node("Vote").hide()
	end_voting()
	
	while not can_add_items:
		await get_tree().create_timer(0.01).timeout
	GDSync.synced_event_create(player.name, 0, [items_to_add])
	player.set_input_mode(true)

func change_vote(plr_name: String, params: Array):
	print("recieved, ", plr_name, ", params are: ", params)
	if not plr_name.contains("changes vote"): return
	if not params[0] is String or not params[1] is String: return
	print("passed")
	
	var player_name = plr_name.replace("changes vote", "")
	var old_panel_name: String = str(params[0])
	var new_panel_name: String = str(params[1])
	var player = world.get_node_or_null(str(GDSync.get_client_id()))
	
	if not player: return
	print("player: ", player_name, " changes vote from ", old_panel_name, " to ", new_panel_name)
	
	var old_panel = main.get_node_or_null(old_panel_name)
	var new_panel = main.get_node_or_null(new_panel_name)
	if player.name == player_name:
		if current_panel == new_panel_name: return
		current_panel = new_panel_name
		if new_panel: current_vote = options.keys()[new_panel.get_meta("key")]
	
	if old_panel: old_panel.get_node("Votes").text = str(str(old_panel.get_node("Votes").text).to_int() - 1)
	if new_panel: new_panel.get_node("Votes").text = str(str(new_panel.get_node("Votes").text).to_int() + 1)
	
func end_voting():
	print("received")
	main.get_node("VotingTime").text = "Calculating all Votes..."
	await get_tree().create_timer(3,false,false,true).timeout
	var best_option = ""
	var ties = []
	var final_choice = ""
	# ------------------------
	var total_votes = {"Option1": {"Name": "", "Votes": 0}, "Option2": {"Name": "", "Votes": 0}, "Option3": {"Name": "", "Votes": 0}}
	var i = 1
	print(total_votes)
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
			elif current_votes == last_votes and current_votes > 0:
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
		items_to_add.append("ehmazing")
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
						if items.size() > 1:
							var random_items = []
							random_items.append_array(items)
							random_items.erase("random")
							item_selection.append_array(random_items)
						else:
							for item in player.get_node("Camera3D").get_children():
								if item.name.contains("RayCast") or item.utility_enabled == true: continue
								if item.shotgun == false: continue
								
								item_selection.append(item.name)
							print(item_selection)
						player.add_item(str(item_selection[randi_range(0,item_selection.size()-1)]))
					else:
						if items.size() == 1:
							for item in player.get_node("Camera3D").get_children():
								if item.name.contains("RayCast") or item.utility_enabled == true: continue
								if item.shotgun == true: continue
					
								item_selection.append(item.name)
							print(item_selection)
							player.add_item(str(item_selection[randi_range(0,item_selection.size()-1)]))
		else:
			if player:
				for item in items:
					player.add_item(str(item))
		if player and player.name == str(GDSync.get_client_id()):
			world.manage_game("start game")
