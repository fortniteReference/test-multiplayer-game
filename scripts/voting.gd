extends Control

@onready var main = $Main
@onready var world = $"../.."

@onready var local_votes = null
@onready var local_panel = null

var option_index = 0

var current_vote = ""
var current_panel = ""
var options = {
	"Original": {"Items": ["pump", "pistol"], "Image": "", "Title": "Original", "Desc": "Nothing better than the og."},
	"Random": {"Items": ["random"], "Image": "", "Title": "Random", "Desc": "ooh gambling!!!"}
}

var index1 = 0
var index2 = 0
var index3 = 0

var player_name = ""
var items_to_add = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GDSync.expose_func(start_voting)
	GDSync.expose_func(end_voting)
	GDSync.expose_func(clear_vote)
	GDSync.expose_func(vote_option1)
	GDSync.expose_func(vote_option2)
	GDSync.expose_func(vote_option3)
	GDSync.synced_event_triggered.connect(add_items)
	
func start_voting_call():
	GDSync.lobby_set_data("Indexes", [randi_range(0,1), randi_range(0,1), randi_range(0,1)])
	
	var indexes: Array = GDSync.lobby_get_data("Indexes", [])
	while indexes.is_empty():
		await GDSync.lobby_data_changed
		indexes = GDSync.lobby_get_data("Indexes", [])
		
	print("indexs: ", indexes[0], indexes[1], indexes[2])
	
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
	
	await get_tree().create_timer(12,false,false,true).timeout
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
			if panel.name.contains("1"):
				GDSync.call_func_all(vote_option1)
			elif panel.name.contains("2"):
				GDSync.call_func_all(vote_option2)
			elif panel.name.contains("3"):
				GDSync.call_func_all(vote_option3)

		vote.pressed.connect(pressed_vote)
		
	var voting_time = main.get_node("VotingTime")
	voting_time.text = "Voting Ends in: 10"
	for i in range(10,0,-1):
		voting_time.text = "Voting Ends in: " + str(i)
		await get_tree().create_timer(1,false,false,true).timeout
	GDSync.call_func_all(end_voting)

func clear_vote():
	if current_vote != "" and player_name == str(GDSync.get_client_id()):
		var other_panel = main.get_node_or_null(str(current_panel))
		if other_panel:
			var other_votes = other_panel.get_node("Votes")
			var reset_votes = str(other_votes.text).to_int() - 1
			other_votes.text = str(reset_votes)

func vote_option1():
	var votes = main.get_node("Voting1/Votes")
	var panel = main.get_node("Voting1")
	if visible and current_vote != str(options.keys()[panel.get_meta("key")]):
		GDSync.call_func_all(clear_vote)
		await get_tree().create_timer(0.25).timeout
		var current_votes = str(votes.text).to_int()
		current_votes += 1
		if player_name == str(GDSync.get_client_id()):
			print("name is equal")
			current_vote = str(options.keys()[panel.get_meta("key")])
			current_panel = "Voting1"
		votes.text = str(current_votes)
		
func vote_option2():
	var votes = main.get_node("Voting2/Votes")
	var panel = main.get_node("Voting2")
	if visible and current_vote != str(options.keys()[panel.get_meta("key")]):
		GDSync.call_func_all(clear_vote)
		await get_tree().create_timer(0.25).timeout
		var current_votes = str(votes.text).to_int()
		current_votes += 1
		if player_name == str(GDSync.get_client_id()):
			print("name is equal")
			current_vote = str(options.keys()[panel.get_meta("key")])
			current_panel = "Voting2"
		votes.text = str(current_votes)
		
func vote_option3():
	var votes = main.get_node("Voting3/Votes")
	var panel = main.get_node("Voting3")
	if visible and current_vote != str(options.keys()[panel.get_meta("key")]):
		GDSync.call_func_all(clear_vote)
		await get_tree().create_timer(0.25).timeout
		var current_votes = str(votes.text).to_int()
		current_votes += 1
		if player_name == str(GDSync.get_client_id()):
			print("name is equal")
			current_vote = str(options.keys()[panel.get_meta("key")])
			current_panel = "Voting3"
		votes.text = str(current_votes)
	
func end_voting():
	var best_vote = 0
	var best_option = "none"
	var ties = []
	var final_choice = ""
	# ------------------------
	var panel1_amount = 0
	var panel2_amount = 0
	var panel3_amount = 0
	# ------------------------
	for panel in main.get_children():
		if not panel is Panel: continue
		
		var votes = panel.get_node("Votes")
		var num_of_votes = str(votes.text).to_int()
		
		if panel.name.contains("1"):
			panel1_amount = num_of_votes
		if panel.name.contains("2"):
			panel2_amount = num_of_votes
		if panel.name.contains("3"):
			panel3_amount = num_of_votes
		
		if num_of_votes > best_vote:
			best_vote = num_of_votes
			best_option = str(options.keys()[panel.get_meta("key")])
		elif num_of_votes == best_vote and best_vote > 0:
			var extra_option = str(options.keys()[panel.get_meta("key")])
			if not ties.has(best_option):
				ties.append(best_option)
			if not ties.has(extra_option):
				ties.append(extra_option)
		elif panel1_amount == 0 and panel2_amount == 0 and panel3_amount == 0:
			var extra_option = str(options.keys()[panel.get_meta("key")])
			ties.append(extra_option)
			
	if ties.size() > 1:
		var index = randi_range(0,ties.size()-1)
		final_choice = str(ties[index])
	else:
		final_choice = best_option
		
	var option = options[final_choice]
	var items = option.get("Items", null)
	
	items_to_add = items
	hide()
	
func add_items(name_player, params):
	if name_player != str(GDSync.get_client_id()) or not params[0] is Array: return
	if params[0][0] == "set index": return
	
	var items = params[0]
	if items != null:
		if items.has("random"):
			# for now, keep like this. later, make it change every round.
			var player = world.get_node_or_null(name_player)
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
			var player = world.get_node_or_null(name_player)
			if player:
				for item in items:
					player.add_item(str(item))
