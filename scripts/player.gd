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
var equip_debounce = false
var reloading = false
var total_damage = 0
# Backups
var fallback_damage = 20
var fallback_cooldown = 0.0
var fallback_ammo = 20

var actions = {}

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

func get_player_equipped_items():
	var player_names = []
	for player in get_parent().get_children():
		if player is CharacterBody3D: player_names.append(player.name)
	
	print(player_names)
	for plr_name in player_names:
		var username: String = GDSync.player_get_username(str(plr_name).to_int())
		var res = await GDSync.account_get_external_document(username, "items")
		var code = res["Code"]
		
		if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
			print("got user items from player ", username)
			
			var equipped: Array = res["Result"]["equipped"]
			var player = get_node_or_null("../" + str(plr_name))
			
			display_accessories(player, equipped)
		else:
			print("did not get user items from player " + username, ", error: ", ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.keys()[code])
	
func display_accessories(player, equipped_items: Array):
	var shop: Node = get_node("../Shop Handler/Items")

	if shop and equipped_items.size() > 0:
		for id in equipped_items:
			var item_node: Node = null
			for item in shop.get_children():
				if item.get_meta("id") == id:
					item_node = item
					break
			if not item_node: continue
			var reference: Node = item_node.get_node(item_node.get_meta("reference"))
			
			print("reference: ", reference)
			if not reference:
				print("no reference found")
				continue
			else:
				if reference.color_enabled:
					print("color is enabled")
					var mesh = player.get_node("MeshInstance3D")
					var og_mat = mesh.get_active_material(0)
					var mat: StandardMaterial3D = og_mat.duplicate()
					mesh.set_surface_override_material(0, mat)
					mat.albedo_color = reference.color
					mat.roughness = reference.roughness
					mat.metallic = reference.metallic

func owner_changed(_owner_id : int) -> void:
	var is_owner : bool = GDSync.is_gdsync_owner(self)
	
	camera.current = is_owner
	if is_owner:
		get_node("CanvasLayer").get_node("player name").text = name
		get_node("CanvasLayer").show()
		
		var res = await GDSync.account_get_document("controls")
		var code = res["Code"]
		
		if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
			print("retrieved settings for: ", GDSync.player_get_username())
			print("settings: ", res["Result"])
			actions = res["Result"]
			
			for action in res["Result"]:
				var set_action = str(action)
				if set_action == "forward":
					set_action = "up"
				elif set_action == "backward":
					set_action = "down"
				elif set_action == "reload":
					set_action = "interact"
					
				var key = actions[action]["key"]
				var keycode = OS.find_keycode_from_string(str(key))
				
				var new_event
				if str(key).contains("mouse"):
					new_event = InputEventMouseButton.new()
					new_event.button_index = str(str(key).replace("mouse", "")).to_int()
				else:
					new_event = InputEventKey.new()
					new_event.keycode = keycode
				
				InputMap.action_erase_events(set_action)
				InputMap.action_add_event(set_action, new_event)
				# print("set action: ", set_action, ", to event: ", new_event)

func _unhandled_input(event) -> void:
	if not GDSync.is_gdsync_owner(self): return
	if event is InputEventMouseMotion:
		var data_handler = get_parent().get_node_or_null("Data Handler")
		
		var aim_str = .001
		var hip_str = .005
		if data_handler:
			aim_str = data_handler.settings.get("aim_sens", .001)
			hip_str = data_handler.settings.get("hip_sens", .005)
		if get_meta("current_item") != "" and Input.is_action_pressed("target"):
			rotate_y(-event.relative.x * aim_str)
			camera.rotate_x(-event.relative.y * aim_str)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		else:
			# print("event is mouse motion")
			rotate_y(-event.relative.x * hip_str)
			camera.rotate_x(-event.relative.y * hip_str)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	elif event is InputEvent:
		if event.is_action_pressed("quit"):
			GDSync.quit()
		elif Input.is_action_just_pressed("interact"):
			var item = camera.get_node_or_null(get_meta("current_item"))
			if item:
				reload(item)
		elif Input.is_key_pressed(KEY_1):
			if get_meta("items").size() >= 1:
				if get_meta("current_item") == get_meta("items")[0]:
					GDSync.synced_event_create(name, 0, ["unequip", ""])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[0] + "equip"), ""])
		elif Input.is_key_pressed(KEY_2):
			if get_meta("items").size() >= 2:
				if get_meta("current_item") == get_meta("items")[1]:
					GDSync.synced_event_create(name, 0, ["unequip", ""])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[1] + "equip"), ""])
		elif Input.is_key_pressed(KEY_3):
			if get_meta("items").size() >= 3:
				if get_meta("current_item") == get_meta("items")[2]:
					GDSync.synced_event_create(name, 0, ["unequip", ""])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[2] + "equip"), ""])
		elif Input.is_key_pressed(KEY_4):
			if get_meta("items").size() >= 4:
				if get_meta("current_item") == get_meta("items")[3]:
					GDSync.synced_event_create(name, 0, ["unequip", ""])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[3] + "equip", "")])
		elif Input.is_key_pressed(KEY_5):
			if get_meta("items").size() >= 5:
				if get_meta("current_item") == get_meta("items")[4]:
					GDSync.synced_event_create(name, 0, ["unequip", ""])
				else:
					GDSync.synced_event_create(name, 0, [str(get_meta("items")[4] + "equip", "")])

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
		if item and item.visible:
			if item.hitscan:
				check_hit(item)
				
	# Aim in
	if get_meta("current_item") != "":
		var item = camera.get_node_or_null(get_meta("current_item"))
		var reticles = $CanvasLayer/HUD/Reticles
		if Input.is_action_just_pressed("target"):
			if item:
				var final_spread: float = item.spread * (1 - (item.spread_reduction * 0.01))
				
				camera.fov = item.fov
				item.position = item.get_meta("new_pos")
				item.set_meta("current_spread", final_spread)
				reticles.adjust_reticle(item, final_spread, item.shotgun, item.custom_reticle)
		if Input.is_action_just_released("target"):
			if item:
				camera.fov = 75
				item.position = item.get_meta("og_pos")
				item.set_meta("current_spread", item.spread)
				reticles.adjust_reticle(item, item.spread, item.shotgun, false)

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
			gui.get_node("item name").text = item.item_name
			gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)
			
			var reticles = hud.get_node_or_null("Reticles")
			if reticles:
				reticles.adjust_reticle(item, item.spread, item.shotgun, false)
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
	
	var pos = Vector3(randf_range(-item.get_meta("current_spread"),item.get_meta("current_spread")),-0.065 + randf_range(-item.get_meta("current_spread"),item.get_meta("current_spread")),-item.weapon_range)
	new_raycast.look_at(camera.to_global(pos))
	
	new_raycast.force_raycast_update()
	if new_raycast.is_colliding():
		var hit_player = new_raycast.get_collider()
		if hit_player is CharacterBody3D:
			var collision_pos = hit_player.to_local(new_raycast.get_collision_point())
			var hit_pos = round(new_raycast.global_position.distance_to(new_raycast.get_collision_point()))
			
			if collision_pos.y > 0.55:
				GDSync.synced_event_create(hit_player.name, 0, [item.name + "true", hit_pos])
			else:
				GDSync.synced_event_create(hit_player.name, 0, [item.name, hit_pos])
	new_raycast.queue_free()

func check_hit(item: Node3D):
	if item.get_meta("on_cooldown") or reloading:
		return
	if item.get_meta("current_ammo") <= 0:
		reload(item)
		return
	item.set_meta("on_cooldown", true)
	raycast.position = Vector3(0,-0.065,0)
	raycast.rotation_degrees = Vector3(0,0,0)
	raycast.target_position = Vector3(0,0,-item.weapon_range)
	
	cooldown = item.cooldown
	
	var burst_amount = 1
	if item.burst_enabled:
		burst_amount = item.burst_amount
	
	for i in range(burst_amount):
		raycast.position = Vector3(0,-0.065,0)
		raycast.rotation_degrees = Vector3(0,0,0)
		raycast.target_position = Vector3(0,0,-item.weapon_range)
		
		if item.get_meta("current_ammo") <= 0:
			reload(item)
			continue
			
		item.set_meta("current_ammo", item.get_meta("current_ammo") - 1)
		GDSync.synced_event_create(name, 0, ["play sound", ""])
		total_damage = 0
		# get_parent()
		var gui = get_node_or_null("CanvasLayer").get_node_or_null("HUD").get_node_or_null("Ammo")
		if gui:
			gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)
		if item.shotgun == true and item.pellets > 0:
			for v in range(item.pellets):
				run_pellet(item)
		else:
			var pos = Vector3(randf_range(-item.get_meta("current_spread"),item.get_meta("current_spread")),-0.065 + randf_range(-item.get_meta("current_spread"),item.get_meta("current_spread")),-item.weapon_range)
			raycast.look_at(camera.to_global(pos))
			raycast.force_raycast_update()
			if raycast.is_colliding():
				var hit_player = raycast.get_collider()
				if hit_player is CharacterBody3D:
					var collision_pos = hit_player.to_local(raycast.get_collision_point())
					var hit_pos = round(raycast.global_position.distance_to(raycast.get_collision_point()))
					
					if collision_pos.y > 0.55:
						GDSync.synced_event_create(hit_player.name, 0, [item.name + " true", hit_pos])
					else:
						GDSync.synced_event_create(hit_player.name, 0, [item.name, hit_pos])
		await get_tree().create_timer(item.burst_cooldown,false,false,true).timeout
	await get_tree().create_timer(cooldown,false,false,true).timeout
	item.set_meta("on_cooldown", false)
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
		if gui:
			gui.get_node("reloading").show()
			gui.get_node("ammo").hide()
		await get_tree().create_timer(reload_time,false,false,true).timeout
	# -----------------------
	reloading = false
	item.set_meta("current_ammo", ammo)
	if gui:
		gui.get_node("reloading").hide()
		gui.get_node("ammo").show()
		gui.get_node("ammo").text = str(item.get_meta("current_ammo")) + "/" + str(ammo)

func play_animation(item: Node3D, degrees: int, reset_time: float, axis = "x"):
	# item determines the item being animated
	# degrees is the degrees of rotation
	# axis default is x, but some items have different rotation axes set.
	var setting: String = "rotation_degrees:" + str(axis)
	var tween: Tween
	
	@warning_ignore("unassigned_variable")
	if tween and tween.is_valid():
		@warning_ignore("unassigned_variable")
		tween.kill()
	tween = item.create_tween()
	
	tween.tween_property(item, setting, degrees, 0.05)
	await get_tree().create_timer(0.05,false,false,true).timeout
	tween = item.create_tween()
	tween.tween_property(item, setting, 0, reset_time)
	
func play_effects(player_name, message):
	if message[0] is Array: return
	if player_name != name or message[0] != "play sound": return
	var item = camera.get_node_or_null(get_meta("current_item"))
	if not item:
		return
	if not item.visible:
		return
	if item.has_node("shoot"):
		item.get_node("shoot").play()
	# -------------------------
	if item.play_animation:
		play_animation(item, item.rotate_degrees, item.reset_time, str(item.rotate_axis))
		
		var og_flash: Sprite3D = camera.get_node("RayCast flash")
		var og_light: OmniLight3D = camera.get_node("RayCast light")
		var muzzle: Node3D = item.get_node_or_null("muzzle pos")
		if item.flash_muzzle and muzzle:
			og_flash.texture = load(str(item.muzzle_image))
			# ----------------------------
			var old_flash: Sprite3D = item.get_node_or_null("cloned flash")
			if old_flash: old_flash.queue_free()
			var old_light: OmniLight3D = item.get_node_or_null("cloned light")
			if old_light: old_light.queue_free()
			# ----------------------------
			var flash: Sprite3D = og_flash.duplicate()
			var light: OmniLight3D = og_light.duplicate()
			item.add_child(flash)
			item.add_child(light)
			flash.name = "cloned flash"
			light.name = "cloned light"
			flash.show()
			light.show()
			light.position = muzzle.position + Vector3(0,0,-0.3)
			flash.position = muzzle.position
			flash.scale = Vector3(item.muzzle_size,item.muzzle_size,item.muzzle_size)
			# ----------------------------
			await get_tree().create_timer(0.15,false,false,true).timeout
			if light != null: light.queue_free()
			if flash != null: flash.queue_free()

func receive_damage(player_name, name_item):
	if player_name == "reset map" or str(name_item[0]).contains("equip"): return
	if name_item[0] is Array: return
	if name_item[0] == "hi" or name_item[0] == "play sound": return
	
	var player = get_parent().get_node_or_null(str(player_name))

	if not player: return
	
	var distance = name_item[1]
	
	var check_item = str(str(name_item[0]).replace("true", ""))
	var hit_head = str(str(name_item[0]).replace(str(check_item), ""))
	var item = camera.get_node_or_null(check_item)

	if player_name != name:
		if item:
			if item.shotgun:
				total_damage += set_damage(item, distance, hit_head)
			damage = set_damage(item, distance, hit_head)
		else:
			damage = fallback_damage
		
		var damage_text = get_parent().get_node_or_null("damage")
		if damage_text and player.name != str(GDSync.get_client_id()):
			show_damage(player, item, hit_head, damage_text)
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
			var won = false
			if player.name == str(GDSync.get_client_id()):
				player.get_parent().manage_game("update scorewinner:loser:" + player.name)
			else:
				show_elimed_player(player.name)
				
				player.get_parent().manage_game("update scorewinner:" + str(GDSync.get_client_id()) + "loser:" + player.name)
				won = true
			check_for_win(won)
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
			
func set_damage(item: Node3D, distance, hit_head) -> int:
	var amount = round(item.falloff_damage * (distance - item.falloff_start))
	var return_damage = 0
	var least_damage = false
	if (item.damage - amount) < item.falloff_minimum and item.falloff_enabled:
		amount = item.falloff_minimum
		least_damage = true
	if amount < 0:
		amount = 0
		
	if item.falloff_enabled:
		if least_damage:
			return_damage = amount
		else:
			return_damage = (item.damage - amount)
	else:
		return_damage = item.damage
	if hit_head == "true":
		if item.falloff_enabled:
			if least_damage:
				return_damage = round(return_damage * item.headshot_multiplier)
			else:
				return_damage = round((item.damage - amount) * item.headshot_multiplier)
		else:
			return_damage = round(return_damage * item.headshot_multiplier)
	return return_damage
			
func show_damage(player, item, hit_head, damage_text: Node3D):
	if item == null: return
	
	if item.shotgun:
		for child in get_parent().get_children():
			if child.name.contains("cloned damage"): child.queue_free()
	var new_damage: Node3D = damage_text.duplicate()
	get_parent().add_child(new_damage)
	new_damage.name = "cloned damage ind"
	new_damage.position = player.position + Vector3(0,1,0)
	new_damage.show()
	get_tree().create_tween().tween_property(new_damage, "position:y", new_damage.position.y + 1.5, 2)
			
	var text: Label3D = new_damage.get_node("label")
	
	if item.shotgun:
		text.text = str(total_damage).replace(".0", "")
	else:
		text.text = str(damage).replace(".0", "")
	if player.get_meta("shield") > 0:
		text.modulate = Color(0.419, 0.676, 0.902, 1.0)
	else:
		if hit_head == "true":
			text.modulate = Color(0.883, 0.873, 0.241, 1.0)
		else:
			text.modulate = Color(1.0, 1.0, 1.0, 1.0)
			
	await get_tree().create_timer(0.5,false,false,true).timeout
	for i in range(100,0,-1):
		if text == null: return
		text.modulate.a = i * 0.01
		text.outline_modulate.a = i * 0.01
		await get_tree().create_timer(0.015,false,false,true).timeout
	if new_damage != null:
		new_damage.queue_free()

func show_elimed_player(player_name: String):
	var gui = $"CanvasLayer/elim gui"
	gui.get_node("plr name").text = str(GDSync.player_get_username(player_name.to_int(), ""))
	get_tree().create_tween().tween_property(gui, "position:y", 450, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(2,false,false,true).timeout
	get_tree().create_tween().tween_property(gui, "position:y", 665, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func check_for_win(won: bool):
	var game = get_parent().get_node_or_null("CanvasLayer/Game")
	var round_panel = game.get_node("BetweenRounds")
	
	round_panel.position.y = -700
	if won:
		round_panel.get_node("title").text = "Victory!"
		round_panel.get_node("message").text = "yes gang🤑🤑🤑"
	else:
		round_panel.get_node("title").text = "Defeat..."
		round_panel.get_node("message").text = "lock in lil bro"
	get_tree().create_tween().tween_property(round_panel, "position:y", 0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1).timeout
	get_tree().create_tween().tween_property(round_panel, "position:y", 700, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	var score = game.get_node_or_null("Score")
	var enemy = score.get_node_or_null("EnemyScore/score")
	var your = score.get_node_or_null("YourScore/score")
	
	if enemy.text == "10/10":
		game.get_node("LoseScreen").show()
		round_panel.hide()
	elif your.text == "10/10":
		game.get_node("WinScreen").show()
		round_panel.hide()
	
	if GDSync.is_host():
		if (enemy.text == "10/10" or your.text == "10/10"):
			for player in get_parent().get_children():
				if player is CharacterBody3D:
					GDSync.lobby_kick_client(str(player.name).to_int())
		else:
			GDSync.synced_event_create("reset map", 0, ["hi", ""])

func reset_map(signal_name, message):
	if message[0] is Array: return
	if str(signal_name) != "reset map": return
	if str(message[0]) != "hi": return
	
	get_parent().manage_game("reset map")
	for player in get_parent().get_children():
		if player and player is CharacterBody3D:
			GDSync.synced_event_create(player.name, 0, ["unequip", ""])
			for i in range(10):
				player.set_meta("health", 100)
				player.set_meta("shield", 100)
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
