extends Control

@onready var other = $Other
@onready var shotgun = $Shotgun
func adjust_reticle(item: Node3D, spread: float, is_shotgun: bool, custom: bool):
	var weapon_range = 1
	if custom:
		other.hide()
		shotgun.hide()
		return
	if item.weapon_range >= 75:
		weapon_range = item.weapon_range
	if is_shotgun:
		other.hide()
		shotgun.show()
		for part in shotgun.get_children():
			if part.name == "Middle":
				continue
			if part.rotation_degrees == 0:
				part.position = part.get_meta("og_position") - Vector2(((spread * 30)/weapon_range), ((spread * 30)/weapon_range))
			if part.rotation_degrees == 90:
				part.position = part.get_meta("og_position") + Vector2(((spread * 30)/weapon_range), -((spread * 30)/weapon_range))
			if part.rotation_degrees == 180:
				part.position = part.get_meta("og_position") - Vector2(-((spread * 30)/weapon_range), -((spread * 30)/weapon_range))
			if part.rotation_degrees == 270:
				part.position = part.get_meta("og_position") - Vector2(((spread * 30)/weapon_range), -((spread * 30)/weapon_range))
	else:
		other.show()
		shotgun.hide()
		for part in other.get_children():
			if part.name == "Middle":
				continue
			if part.name == "Left":
				part.position.x = part.get_meta("og_position").x - round(((spread * 30)/weapon_range))
			if part.name == "Right":
				part.position.x = part.get_meta("og_position").x + round(((spread * 30)/weapon_range))
			if part.name == "Top":
				part.position.y = part.get_meta("og_position").y - round(((spread * 30)/weapon_range))
			if part.name == "Bottom":
				part.position.y = part.get_meta("og_position").y + round(((spread * 30)/weapon_range))
				
func hide_reticles():
	other.hide()
	shotgun.hide()
