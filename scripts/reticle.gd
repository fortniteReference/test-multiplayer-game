extends Control

@onready var other = $Other
@onready var shotgun = $Shotgun
func adjust_reticle(spread: float, is_shotgun: bool):
	if is_shotgun:
		other.hide()
		shotgun.show()
		for part in shotgun.get_children():
			if part.name == "Middle":
				continue
			if part.rotation_degrees == 0:
				part.position = part.get_meta("og_position") - Vector2(spread * 30, spread * 30)
			if part.rotation_degrees == 90:
				part.position = part.get_meta("og_position") + Vector2(spread * 30, -(spread * 30))
			if part.rotation_degrees == 180:
				part.position = part.get_meta("og_position") - Vector2(-(spread * 30), -(spread * 30))
			if part.rotation_degrees == 270:
				part.position = part.get_meta("og_position") - Vector2(spread * 30, -(spread * 30))
	else:
		other.show()
		shotgun.hide()
		for part in other.get_children():
			if part.name == "Middle":
				continue
			if part.name == "Left":
				part.position.x = part.get_meta("og_position").x - round(spread * 30)
			if part.name == "Right":
				part.position.x = part.get_meta("og_position").x + round(spread * 30)
			if part.name == "Top":
				part.position.y = part.get_meta("og_position").y - round(spread * 30)
			if part.name == "Bottom":
				part.position.y = part.get_meta("og_position").y + round(spread * 30)
				
func hide_reticles():
	other.hide()
	shotgun.hide()
