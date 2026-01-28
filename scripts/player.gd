extends CharacterBody3D

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
# @onready var anim_player = $AnimationPlayer

const SPEED = 7.75
const JUMP_VELOCITY = 8.0

var health = 100
var shield = 100
var cooldown = 0.0
var damage = 0
var ammo = 1
var shoot_debounce = false
var equip_debounce = false
var reloading = false
# Backups
var fallback_damage = 20
var fallback_cooldown = 0.0
var fallback_ammo = 20

func _ready() -> void:
	GDSync.connect_gdsync_owner_changed(self, owner_changed)
	GDSync.synced_event_triggered.connect(reset_map)
	GDSync.synced_event_triggered.connect(receive_damage)
	GDSync.synced_event_triggered.connect(equip_item)
	GDSync.synced_event_triggered.connect(unequip_items)
	GDSync.synced_event_triggered.connect(play_effects)
	
func set_input_mode(on: bool):
	if on:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func owner_changed(_owner_id : int) -> void:
	var is_owner : bool = GDSync.is_gdsync_owner(self)
	
	camera.current = is_owner
	if is_owner:
		get_node("CanvasLayer").get_node("player name").text = name
		get_node("CanvasLayer").show()

func _unhandled_input(event) -> void:
	# print("ran input, ", event)
	if not GDSync.is_gdsync_owner(self): return
	if event is InputEventMouseMotion:
		# print("event is mouse motion")
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	elif event is InputEvent:
		if event.is_action_pressed("quit"):
			get_tree().quit()
		elif Input.is_action_just_pressed("interact"):
			var item = camera.get_node_or_null(get_meta("current_item"))
			if item:
				reload(item)
		elif Input.is_key_pressed(KEY_1):
			if get_meta("items").size() >= 1:
				if get_meta("current_item") == get_meta("items")[0]:
					GDSync.synced_event_create(name, 0, ["unequip"])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[0] + "equip")])
		elif Input.is_key_pressed(KEY_2):
			if get_meta("items").size() >= 2:
				if get_meta("current_item") == get_meta("items")[1]:
					GDSync.synced_event_create(name, 0, ["unequip"])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[1] + "equip")])
		elif Input.is_key_pressed(KEY_3):
			if get_meta("items").size() >= 3:
				if get_meta("current_item") == get_meta("items")[2]:
					GDSync.synced_event_create(name, 0, ["unequip"])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[2] + "equip")])
		elif Input.is_key_pressed(KEY_4):
			if get_meta("items").size() >= 4:
				if get_meta("current_item") == get_meta("items")[3]:
					GDSync.synced_event_create(name, 0, ["unequip"])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[3] + "equip")])
		elif Input.is_key_pressed(KEY_5):
			if get_meta("items").size() >= 5:
				if get_meta("current_item") == get_meta("items")[4]:
					GDSync.synced_event_create(name, 0, ["unequip"])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[4] + "equip")])

func _physics_process(delta: float) -> void:
	if not GDSync.is_gdsync_owner(self): return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("shoot") and get_meta("current_item") != "":
		var item = camera.get_node_or_null(str(get_meta("current_item")))
		if item:
			if item.visible and item.hitscan == true:
				check_hit(item)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	"""
	if str(anim_player.current_animation).contains("_shoot"):
		pass
	else:
		anim_player.play("idle")
	"""
	move_and_slide()
# --------------------------
# Item Handling
# --------------------------
func add_item(name_item: String):
	print("added item ", name_item, " to player ", name)
	get_meta("items").append(name_item)
	set_meta("items", get_meta("items"))
	update_hotbar()
	
func update_hotbar():
	var canvas = get_node_or_null("CanvasLayer")
	var hud = canvas.get_node_or_null("HUD")
	var hotbar = hud.get_node_or_null("Hotbar")
	if hotbar:
		for slot in hotbar.get_children():
			slot.get_node("image").texture = null
		for slot in hotbar.get_children():
			var slot_num = str(slot.name.replace("slot", "")).to_int()
		
			if get_meta("items").size() < slot_num + 1:
				break
			var cam = get_node_or_null("Camera3D")
			var item = camera.get_node_or_null(str(get_meta("items")[slot_num]))
			if cam and item:
				slot.get_node("image").texture = load(str(item.image))

func equip_item(player_name: String, n_item):
	if n_item[0] is Array: return
	if equip_debounce or player_name != name or not str(n_item[0]).contains("equip"):
		return
	var name_item = str(n_item[0]).replace("equip", "")
	var item = camera.get_node_or_null(name_item)
	if get_meta("items").has(name_item) and item:
		equip_debounce = true
		# get_parent()
		var canvas = get_node_or_null("CanvasLayer")
		var hud = canvas.get_node_or_null("HUD")
		var hotbar = hud.get_node_or_null("Hotbar")
		var gui = hud.get_node_or_null("Ammo")
		if hotbar and GDSync.is_gdsync_owner(self):
			for slot in hotbar.get_children():
				slot.get_theme_stylebox("panel").border_color = Color(0.533, 0.882, 0.541, 0.0)
		
		ammo = item.ammo
		if item.get_meta("already_equipped") == true:
			pass
		else:
			item.set_meta("already_equipped", true)
			item.set_meta("current_ammo", ammo)

		if gui and GDSync.is_gdsync_owner(self):
			gui.show()
			gui.get_node("item name").text = name_item
			gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)
			
			var reticles = hud.get_node_or_null("Reticles")
			if reticles:
				reticles.adjust_reticle(item.spread, item.shotgun)
		# print("equipped ", name_item, " at player ", name)
		set_meta("current_item", name_item)
		for other in camera.get_children():
			if other.name.contains("RayCast"):
				continue
			other.hide()
		item.show()
		if hotbar and GDSync.is_gdsync_owner(self):
			for slot in hotbar.get_children():
				if slot.get_node("image").texture == null:
					continue
				if str(slot.get_node("image").texture.resource_path) == str(camera.get_node(name_item).image):
					slot.get_theme_stylebox("panel").border_color = Color(0.533, 0.882, 0.541, 1.0)
		await get_tree().create_timer(0.15,false,false,true).timeout
		equip_debounce = false

func unequip_items(player_name, message):
	if message[0] is Array: return
	if equip_debounce or player_name != name or message[0] != "unequip":
		return
	equip_debounce = false
	# get_parent()
	var canvas = get_node_or_null("CanvasLayer")
	var hud = canvas.get_node_or_null("HUD")
	var hotbar = hud.get_node_or_null("Hotbar")
	var gui = hud.get_node_or_null("Ammo")
	var reticles = hud.get_node_or_null("Reticles")
	set_meta("current_item", "")
	for other in camera.get_children():
		if other.name.contains("RayCast"):
			continue
		other.hide()
	if gui:
		gui.hide()
	if reticles:
		reticles.hide_reticles()
	if hotbar:
		for slot in hotbar.get_children():
			slot.get_theme_stylebox("panel").border_color = Color(0.533, 0.882, 0.541, 0.0)
	await get_tree().create_timer(0.15,false,false,true).timeout
	equip_debounce = false
# --------------------------
# --------------------------
func run_pellet(item: Node3D):
	var new_raycast = raycast.duplicate()
	camera.add_child(new_raycast)
	new_raycast.name = "cloned RayCast"
	new_raycast.position = Vector3(0,-0.056,0)
	
	var pos = Vector3(randf_range(-item.spread,item.spread),-0.065 + randf_range(-item.spread,item.spread),-item.weapon_range)
	new_raycast.look_at(camera.to_global(pos))
	
	new_raycast.force_raycast_update()
	if new_raycast.is_colliding():
		var hit_player = new_raycast.get_collider()
		if hit_player is CharacterBody3D:
			var collision_pos = hit_player.to_local(new_raycast.get_collision_point())
			
			if collision_pos.y > 0.55:
				GDSync.synced_event_create(hit_player.name, 0, [item.name + "true"])
			else:
				GDSync.synced_event_create(hit_player.name, 0, [item.name])
	new_raycast.queue_free()
					
func check_hit(item: Node3D):
	if shoot_debounce or reloading:
		return
	if item.get_meta("current_ammo") <= 0:
		reload(item)
		return
	shoot_debounce = true
	raycast.position = Vector3(0,-0.065,0)
	raycast.rotation_degrees = Vector3(0,0,0)
	raycast.target_position = Vector3(0,0,-item.weapon_range)
	
	cooldown = item.cooldown
	
	item.set_meta("current_ammo", item.get_meta("current_ammo") - 1)
	GDSync.synced_event_create(name, 0, ["play sound"])
	# get_parent()
	var gui = get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("Ammo")
	if gui:
		gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)
	if item.shotgun == true and item.pellets > 0:
		for i in range(item.pellets):
			run_pellet(item)
	else:
		var pos = Vector3(randf_range(-item.spread,item.spread),-0.065 + randf_range(-item.spread,item.spread),-item.weapon_range)
		raycast.look_at(camera.to_global(pos))
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			if hit_player is CharacterBody3D:
				var collision_pos = hit_player.to_local(raycast.get_collision_point())
				
				if collision_pos.y > 0.55:
					GDSync.synced_event_create(hit_player.name, 0, [item.name + "true"])
				else:
					GDSync.synced_event_create(hit_player.name, 0, [item.name])
	await get_tree().create_timer(cooldown,false,false,true).timeout
	shoot_debounce = false
	raycast.position = Vector3(0,-0.065,0)
	raycast.rotation_degrees = Vector3(0,0,0)
	
func reload(item: Node3D):
	if reloading or item.get_meta("current_ammo") == ammo:
		return
	reloading = true
	if item.has_node("reload"):
		item.get_node("reload").stop()
		item.get_node("reload").play()
	# -----------------------
	var reload_time = 3.0
	if item.reload_time > 0.0:
		reload_time = item.reload_time
	# -----------------------
	var gui = get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("Ammo")
	if item.shotgun_reload == true:
		if gui:
			gui.get_node("reloading").show()
		for i in range(ammo-item.get_meta("current_ammo")):
			for u in range(round(reload_time*50)):
				if Input.is_action_pressed("shoot") and item.get_meta("current_ammo") > 0:
					reloading = false
					if gui:
						gui.get_node("reloading").hide()
					return
				await get_tree().create_timer(0.02,false,false,true).timeout
			item.set_meta("current_ammo", item.get_meta("current_ammo") + 1)
			gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)
	else:
		item.set_meta("current_ammo", 0)
		await get_tree().create_timer(reload_time,false,false,true).timeout
		if gui:
			gui.get_node("reloading").show()
			gui.get_node("ammo").hide()
	# -----------------------
	reloading = false
	item.set_meta("current_ammo", ammo)
	if gui:
		gui.get_node("reloading").hide()
		gui.get_node("ammo").show()
		gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)
	
func play_effects(player_name, message):
	if message[0] is Array: return
	if player_name != name or message[0] != "play sound": return
	var item = camera.get_node_or_null(get_meta("current_item"))
	if not item:
		shoot_debounce = false
		return
	if not item.visible:
		return
	if item.has_node("shoot"):
		item.get_node("shoot").play()
		
	# var flash = item.get_node("MuzzleFlash")
	"""
	anim_player.stop()
	anim_player.play(str(get_meta("current_item")) + "_shoot")
	"""
	# flash.restart()
	# flash.emitting = true
	# stop_effects(flash)
	
func stop_effects(flash):
	await get_tree().create_timer(0.3,false,false,true).timeout
	flash.emitting = false

func receive_damage(player_name, name_item):
	if player_name == "reset map" or str(name_item[0]).contains("equip"): return
	if name_item[0] is Array: return
	if name_item[0] == "hi" or name_item[0] == "play sound": return
	
	var player = get_parent().get_node_or_null(str(player_name))

	if not player: return
	
	var check_item = str(name_item[0]).replace("true", "")
	var hit_head = str(name_item[0]).replace(str(check_item), "")
	var item = camera.get_node_or_null(check_item)
	if player_name != name:
		if item:
			damage = item.damage
			if hit_head == "true":
				damage = round(damage * item.headshot_multiplier)
		else:
			damage = fallback_damage

		if player.get_meta("shield") > 0:
			if player.get_meta("shield") < damage:
				var total = damage - player.get_meta("shield")
				player.set_meta("shield", 0.0)
				player.set_meta("health", player.get_meta("health") - total)
			else:
				player.set_meta("shield", player.get_meta("shield") - damage)
		else:
			player.set_meta("health", player.get_meta("health") - damage)
		if player.get_meta("health") <= 0:
			GDSync.synced_event_create("reset map", 0, ["hi"])
	if player.name == name:
		for i in range(5):
			var gui = player.get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("HealthGui")
			# var gui = get_parent().get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("HealthGui")
			var health_bar = gui.get_node_or_null("HealthBar")
			var shield_bar = gui.get_node_or_null("ShieldBar")
			var health_text = gui.get_node_or_null("health text")
			var shield_text = gui.get_node_or_null("shield text")
			if health_bar and shield_bar:
				health_bar.value = player.get_meta("health")
				shield_bar.value = player.get_meta("shield")
			if health_text and shield_text:
				health_text.text = str(player.get_meta("health")).replace(".0", "")
				shield_text.text = str(player.get_meta("shield")).replace(".0", "")
			await get_tree().process_frame

func reset_map(signal_name, message):
	if message[0] is Array: return
	if str(signal_name) != "reset map": return
	if str(message[0]) != "hi": return
	
	for player in get_parent().get_children():
		if player is CharacterBody3D:
			GDSync.synced_event_create(player.name, 0, ["unequip"])
			for i in range(10):
				player.set_meta("health", 100)
				player.set_meta("shield", 100)
				player.position = Vector3.ZERO
				for weapon in player.get_node("Camera3D").get_children():
					if weapon.name.contains("RayCast"):
						continue
					var ammo_gui = player.get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("Ammo")
					weapon.set_meta("current_ammo", weapon.ammo)
					if ammo_gui:
						ammo_gui.get_node("reloading").hide()
						ammo_gui.get_node("ammo").text = str(weapon.get_meta("current_ammo")) + "/" + str(weapon.ammo)
				await get_tree().create_timer(0.01,false,false,true).timeout
			var gui = player.get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("HealthGui")
			
			var health_bar = gui.get_node_or_null("HealthBar")
			var shield_bar = gui.get_node_or_null("ShieldBar")
			var health_text = gui.get_node_or_null("health text")
			var shield_text = gui.get_node_or_null("shield text")
			
			if health_bar and shield_bar:
				health_bar.value = player.get_meta("health")
				shield_bar.value = player.get_meta("shield")
			if health_text and shield_text:
				health_text.text = str(player.get_meta("health")).replace(".0", "")
				shield_text.text = str(player.get_meta("shield")).replace(".0", "")
