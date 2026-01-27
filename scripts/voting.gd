extends Control

@onready var main = $Main
@onready var world = $"../.."

var current_vote = ""
var current_panel = ""
var options = {
	"Original": {"Items": ["pump", "pistol"], "Image": "", "Title": "Original", "Desc": "Nothing better than the og."},
	"Random": {"Items": ["random"], "Image": "", "Title": "Random", "Desc": "ooh gambling!!!"}
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func start_voting():
	var player = world.get_node_or_null(str(GDSync.get_client_id()))
	if player:
		player.set_input_mode(false)
	for panel in main.get_children():
		var index = randi_range(0, options.size() - 1)
		var option = options.values()[index]
		# -----------------------
		var image = panel.get_node("Image/image")
		var title = panel.get_node("Title")
		var desc = panel.get_node("Desc")
		var vote = panel.get_node("Vote")
		var votes = panel.get_node("Votes")
		# -----------------------
		title.text = str(option.get("Title", "null"))
		desc.text = str(option.get("Desc", "null"))
		
		var get_image = str(option.get("Image", "null"))
		if get_image != "null" and get_image != "" and get_image.contains("res://"):
			image.texture = load(get_image)
			
		var pressed_vote = func():
			if visible and current_vote != str(options.keys()[index]):
				if current_vote != "":
					var other_panel = main.get_node_or_null(str(current_panel))
					if other_panel:
						var other_votes = other_panel.get_node("Votes")
						var reset_votes = str(other_votes.text).to_int() - 1
						other_votes.text = str(reset_votes)
				var current_votes = str(votes.text).to_int()
				current_votes += 1
				current_vote = str(options.keys()[index])
				current_panel = panel.name
				votes.text = str(current_votes)

		vote.pressed.connect(pressed_vote)
