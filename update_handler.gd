extends Node

# 1. SET YOUR DETAILS HERE
const CURRENT_VERSION = "v1.0.6" # Change this every time you make a new version
const REPO_PATH = "fortniteReference/test-multiplayer-game"
const PCK_FILENAME = "test_multiplayer.pck" # "test_multiplayer.pck" # Must match the file name you upload to GitHub
const developer_mode = false # change to false before exporting
var checking_updates = false
var download_start_time = 0.0
var total_bytes = 0

# 2. THE URLS (Built automatically)
const API_URL = "https://api.github.com/repos/fortniteReference/test-multiplayer-game/releases/latest"
const DOWNLOAD_URL = "https://github.com/fortniteReference/test-multiplayer-game/releases/latest/download/" + PCK_FILENAME
var SAVE_PATH = OS.get_executable_path().get_base_dir() + "/test_multiplayer.pck"

@onready var http = $HTTPRequest
@onready var canvas = $canvas
@onready var title = $canvas/Panel/title
@onready var desc = $canvas/Panel/desc
@onready var update = $canvas/Panel/update
@onready var skip = $canvas/Panel/skip
@onready var task = $"../CanvasLayer/Waiting/Panel/task"

func start_check():
	# Connect the signal for the version check
	checking_updates = true
	http.request_completed.connect(_on_version_check_completed)
	check_for_updates()

func check_for_updates():
	print("Checking GitHub for updates...")
	var error = http.request(API_URL)
	if error != OK:
		print("Error starting version check.")

func _on_version_check_completed(_result, response_code, _headers, body):
	# Disconnect this signal so we can reuse the node for the download
	http.request_completed.disconnect(_on_version_check_completed)
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var latest_version: String = json.get("name", "")
		
		if latest_version != "" and latest_version != CURRENT_VERSION and not developer_mode:
			desc.text = "Update " + latest_version + " is available.
			It is recommended that you update to the newest version. 
			Not updating may cause some parts of the game to break or not work correctly.
			(Your version: " + CURRENT_VERSION + ")"
			canvas.show()
		else:
			if developer_mode:
				print("developer mode is enabled.")
			print("Game is up to date (Version: ", CURRENT_VERSION, "). Skipping.")
			checking_updates = false
			$"..".checked_for_updates(false)
	else:
		print("Failed to reach GitHub API. Code: ", response_code)

func start_download():
	# Connect the signal for the actual file download
	http.request_completed.connect(_on_download_completed)
	http.download_file = SAVE_PATH # Tell Godot to save to disk, not memory
	var error = http.request(DOWNLOAD_URL)
	
	if error != OK:
		title.text = "Download Failed"
		desc.text = "The download could not start due to an error. Please reopen the app."
	else:
		while_downloading()

func _on_download_completed(_result, response_code, _headers, _body):
	if response_code == 200:
		title.text = "Update Successful!"
		desc.text = "For the update to take effect, please close the app and reopen."
		checking_updates = false
	else:
		title.text = "Download Failed"
		desc.text = "The download failed due to an error. Error code: " + str(response_code) + "\n\nIf you would like to retry, please reopen the app."

func _on_update_pressed() -> void:
	start_download()
	update.hide()
	skip.hide()
	title.text = "Updating..."
	desc.text = "Please wait while the game updates. DO NOT CLOSE THE APP!"

func _on_skip_pressed() -> void:
	checking_updates = false
	canvas.hide()
	$"..".checked_for_updates(false)

func while_downloading():
	var counter = 0
	var time_elapsed = 0
	while checking_updates:
		if http.get_http_client_status() == HTTPClient.STATUS_BODY:
			var body_size = http.get_body_size() # Total size of the file
			var downloaded_bytes = http.get_downloaded_bytes()
			
			if body_size > 0 and downloaded_bytes > 0:
				counter += 1
				if counter % 2 == 0: time_elapsed += 1
				if time_elapsed > 0:
					var bytes_per_sec = downloaded_bytes / time_elapsed
					var bytes_remaining = body_size - downloaded_bytes
					
					# 2. Calculate Time Remaining
					var seconds_left = bytes_remaining / bytes_per_sec
					
					# 3. Format the text for your UI
					update_etr_ui(seconds_left, bytes_per_sec)
		await get_tree().create_timer(0.5).timeout

func update_etr_ui(seconds: float, speed: float):
	@warning_ignore("integer_division")
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	var mbs = (round(speed * 100)/100) / 1000000
	
	desc.text = "Please wait while the game updates. DO NOT CLOSE THE APP!\n"
	desc.text += "Speed: " + str(mbs).replace(".0", "") + " Megabytes/Second.\n"
	desc.text += "Estimated time remaining: %02d:%02d" % [mins, secs]
