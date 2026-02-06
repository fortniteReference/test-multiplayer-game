extends CanvasLayer

const LOCK_FILE_PATH = "user://game.lock"

func _ready() -> void:
	check_instance_lock()

func check_instance_lock() -> void:
	# 1. Check if a lock file already exists from a previous session
	if FileAccess.file_exists(LOCK_FILE_PATH):
		var f = FileAccess.open(LOCK_FILE_PATH, FileAccess.READ)
		var last_heartbeat = f.get_var()
		f.close()
		
		# 2. Verify if the instance is actually active. 
		# If the timestamp is less than 5 seconds old, another window is open.
		var current_time = Time.get_unix_time_from_system()
		if current_time - last_heartbeat < 5 and get_meta("testing") == false:
			$Warning.show()
			$"../../CanvasLayer".hide()
			await get_tree().create_timer(5,false,false,true).timeout
			GDSync.quit()
			return

	# 3. Create/Update the lock file and start a heartbeat timer
	update_lock_heartbeat()
	
	var timer = Timer.new()
	timer.wait_time = 4.0 # Update every 4 seconds
	timer.autostart = true
	timer.timeout.connect(update_lock_heartbeat)
	add_child(timer)

func update_lock_heartbeat() -> void:
	# Writes the current time to the file so other instances know this one is alive
	var f = FileAccess.open(LOCK_FILE_PATH, FileAccess.WRITE)
	f.store_var(Time.get_unix_time_from_system())
	f.close()

func _notification(what: int) -> void:
	# 4. Clean up the lock file when the user closes the window normally
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if FileAccess.file_exists(LOCK_FILE_PATH):
			DirAccess.remove_absolute(LOCK_FILE_PATH)
		get_tree().quit()
