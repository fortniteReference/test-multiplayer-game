extends CharacterBody3D

@onready var camera = $Camera3D
@onready var raycast = $Camera3D/RayCast3D
# @onready var anim_player = $AnimationPlayer

const SPEED = 6.0
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
	GDSync.expose_func(reset_map)
	GDSync.synced_event_triggered.connect(receive_damage)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func owner_changed(_owner_id : int) -> void:
	var is_owner : bool = GDSync.is_gdsync_owner(self)
	
	if is_owner:
		add_item("pistol")
	camera.current = is_owner
	if is_owner:
		await get_tree().create_timer(0.5).timeout
		# get_parent()
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
					unequip_items.rpc()
				else:
					equip_item.rpc(get_meta("items")[0])
		elif Input.is_key_pressed(KEY_2):
			if get_meta("items").size() >= 2:
				if get_meta("current_item") == get_meta("items")[1]:
					unequip_items.rpc()
				else:
					equip_item.rpc(get_meta("items")[1])
		elif Input.is_key_pressed(KEY_3):
			if get_meta("items").size() >= 3:
				if get_meta("current_item") == get_meta("items")[2]:
					unequip_items.rpc()
				else:
					equip_item.rpc(get_meta("items")[2])
		elif Input.is_key_pressed(KEY_4):
			if get_meta("items").size() >= 4:
				if get_meta("current_item") == get_meta("items")[3]:
					unequip_items.rpc()
				else:
					equip_item.rpc(get_meta("items")[3])
		elif Input.is_key_pressed(KEY_5):
			if get_meta("items").size() >= 5:
				if get_meta("current_item") == get_meta("items")[4]:
					unequip_items.rpc()
				else:
					equip_item.rpc(get_meta("items")[4])

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
				play_effects.rpc()

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
@rpc("call_local")
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

@rpc("call_local")
func equip_item(name_item: String):
	if equip_debounce:
		return
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

@rpc("call_local")
func unequip_items():
	if equip_debounce:
		return
	equip_debounce = false
	# get_parent()
	var canvas = get_node_or_null("CanvasLayer")
	var hud = canvas.get_node_or_null("HUD")
	var hotbar = hud.get_node_or_null("Hotbar")
	var gui = hud.get_node_or_null("Ammo")
	set_meta("current_item", "")
	for other in camera.get_children():
		if other.name.contains("RayCast"):
			continue
		other.hide()
	if gui:
		gui.hide()
	if hotbar:
		for slot in hotbar.get_children():
			slot.get_theme_stylebox("panel").border_color = Color(0.533, 0.882, 0.541, 0.0)
	await get_tree().create_timer(0.15,false,false,true).timeout
	equip_debounce = false
# --------------------------
# --------------------------
func check_hit(item: Node3D):
	if shoot_debounce or reloading:
		return
	if item.get_meta("current_ammo") <= 0:
		reload(item)
		return
	raycast.position = Vector3(0,-0.065,0)
	raycast.rotation_degrees = Vector3(0,0,0)
	raycast.target_position = Vector3(0,0,-item.weapon_range)
	
	item.set_meta("current_ammo", item.get_meta("current_ammo") - 1)
	# get_parent()
	var gui = get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("Ammo")
	if gui:
		gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)
	if item.shotgun == true and item.pellets > 0:
		for i in range(item.pellets):
			var pos = Vector3(randf_range(-item.spread,item.spread),-0.065 + randf_range(-item.spread,item.spread),-item.weapon_range)
			raycast.look_at(camera.to_global(pos))
			if raycast.is_colliding():
				var hit_player = raycast.get_collider()
				if hit_player is CharacterBody3D:
					hit_player.receive_damage.rpc_id(str(hit_player.name).to_int(), item.name)
			await get_tree().process_frame
	else:
		var pos = Vector3(randf_range(-item.spread,item.spread),-0.065 + randf_range(-item.spread,item.spread),-item.weapon_range)
		raycast.look_at(camera.to_global(pos))
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			if hit_player is CharacterBody3D:
				print(str(hit_player.name).to_int())
				GDSync.synced_event_create(hit_player.name, 0, [item.name])
				# GDSync.expose_func(receive_damage)
				# GDSync.call_func_all(receive_damage, [hit_player, item.name])
			else:
				print("hit player is not character body: ", hit_player)
	await get_tree().create_timer(cooldown).timeout
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
	# get_parent()
	var gui = get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("Ammo")
	if gui:
		gui.get_node("reloading").show()
		gui.get_node("ammo").hide()
	item.set_meta("current_ammo", 0)
	# -----------------------
	await get_tree().create_timer(reload_time,false,false,true).timeout
	reloading = false
	item.set_meta("current_ammo", ammo)
	if gui:
		gui.get_node("reloading").hide()
		gui.get_node("ammo").show()
		gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)
	
@rpc("call_local")
func play_effects():
	if shoot_debounce or reloading:
		return
	var item = camera.get_node_or_null(get_meta("current_item"))
	if not item:
		shoot_debounce = false
		return
	if not item.visible:
		return
	if item.has_node("shoot"):
		item.get_node("shoot").play()
		
	# var flash = item.get_node("MuzzleFlash")
		
	shoot_debounce = true
	"""
	anim_player.stop()
	anim_player.play(str(get_meta("current_item")) + "_shoot")
	"""
	# flash.restart()
	# flash.emitting = true
	# stop_effects(flash)
	if item.cooldown > 0.0:
		cooldown = item.cooldown
		await get_tree().create_timer(cooldown,false,false,true).timeout
	else:
		await get_tree().create_timer(fallback_cooldown,false,false,true).timeout
		
	shoot_debounce = false
	
func stop_effects(flash):
	await get_tree().create_timer(0.3,false,false,true).timeout
	flash.emitting = false

func receive_damage(player_name, name_item):
	var player = get_parent().get_node_or_null(str(player_name))
	print(player, player_name, str(name_item[0]))
	if not player: return
	if player.name != name: return
	print(name + " is receiveing")
	
	var item = camera.get_node_or_null(str(name_item[0]))
	if item:
		damage = item.damage
	else:
		damage = fallback_damage
	
	print("player is: ", player.name)
	print(player.get_meta("shield") - damage)
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
		for other in get_parent().get_children():
			if other is CharacterBody3D:
				GDSync.call_func_on(str(other.name).to_int(), reset_map)
	if player.name == name:
		var gui = player.get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("HealthGui")
		# var gui = get_parent().get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("HealthGui")
		var health_bar = gui.get_node_or_null("HealthBar")
		var shield_bar = gui.get_node_or_null("ShieldBar")
		var health_text = gui.get_node_or_null("health text")
		var shield_text = gui.get_node_or_null("shield text")
		print("player name is the same: ", player.name, name)
		if health_bar and shield_bar:
			health_bar.value = player.get_meta("health")
			shield_bar.value = player.get_meta("shield")
		if health_text and shield_text:
			health_text.text = str(player.get_meta("health"))
			shield_text.text = str(player.get_meta("shield"))
	
func reset_map():
	for i in range(10):
		set_meta("health", 100)
		set_meta("shield", 100)
		position = Vector3.ZERO
		await get_tree().create_timer(0.01,false,false,true).timeout
