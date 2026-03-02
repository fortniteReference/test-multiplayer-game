extends Node

@onready var world = $".."
@onready var signup = $CanvasLayer/Signup
@onready var login = $CanvasLayer/Login
@onready var waiting = $"../CanvasLayer/Waiting"
@onready var verify = $CanvasLayer/Verify

var current_email = ""
var current_password = ""

func _on_signup_pressed() -> void:
	print("received")
	var email_checks = [".org", ".com"]
	
	var email = $CanvasLayer/Signup/Panel/email
	var user = $CanvasLayer/Signup/Panel/username
	var password = $CanvasLayer/Signup/Panel/password
	var error = $CanvasLayer/Signup/Panel/Error
	
	var check1 = false
	for check in email_checks:
		if str(email.text).contains("@") and str(email.text).contains(check):
			check1 = true
			break
	if check1:
		print("check 1 passed")
	else:
		print("check 1 failed")
		
	var check2 = false
	if str(password.text).length() >= 8:
		check2 = true
		
	if check2:
		print("check 2 passed")
	else:
		print("check 2 failed")
	print(password.text)
		
	var check3 = false
	if str(user.text).length() >= 3: # change to use ENUM check to check for taken username
		check3 = true
		
	if check3:
		print("check 3 passed")
	else:
		print("check 3 failed")
	print(user.text)
	
	error.text = "Checking..."
	if check1 and check2 and check3:
		print("got in")
		if str(user.text).contains(" "):
			str(user.text).replace(" ", "_")
			
		var response = await GDSync.account_create(str(email.text), str(user.text), str(password.text))
		
		print("response: ", response)
		print("Error Name: ", ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.keys()[response])

		if response == ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.EMAIL_ALREADY_EXISTS:
			error.text = "ERROR: The provided email already exists."
		elif response == ENUMS.ACCOUNT_CREATION_RESPONSE_CODE.SUCCESS:
			var verify_button = $CanvasLayer/Verify/Panel/verify
			var extra_text = $CanvasLayer/Verify/Panel/code/Label
			
			print("account created")
			current_email = str(email.text)
			current_password = str(password.text)
			signup.hide()
			login.hide()
			verify.show()
			
			extra_text.text = "Enter the 6-Digit code we sent to " + current_email + "."
			
			verify_button.pressed.connect(verify_pressed)
	else:
		if not check1:
			error.text = "ERROR: The provided email is not valid."
		if not check2:
			error.text = "ERROR: The provided password is not at least 8 characters."
		if not check3:
			error.text = "ERROR: The provided username is not at least 3 characters."
			
func _on_resend_pressed():
	GDSync.account_resend_verification_code(current_email, current_password)

func verify_pressed():
	var error = $CanvasLayer/Verify/Panel/Error
	error.text = "Checking..."
	var code = await GDSync.account_verify(current_email, $CanvasLayer/Verify/Panel/code.text, 600)
	
	if code == ENUMS.ACCOUNT_VERIFICATION_RESPONSE_CODE.INCORRECT_CODE:
		error.text = "ERROR: This doesn't seem to be the code for this account."
	elif code == ENUMS.ACCOUNT_VERIFICATION_RESPONSE_CODE.ALREADY_VERIFIED:
		error.text = "ERROR: This user is already verified."
	elif code == ENUMS.ACCOUNT_VERIFICATION_RESPONSE_CODE.SUCCESS:
		await GDSync.account_login(current_email, current_password, 86400)
		error.text = "Logged in, thank you!"
		
		waiting.position.y = -700
		waiting.show()
		get_tree().create_tween().tween_property(login, "position:y", 700, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		get_tree().create_tween().tween_property(waiting, "position:y", 0, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(1.25,false,false,true).timeout
		login.hide()
		signup.hide()
		$CanvasLayer.hide()
		$"../Lobby".show()
		await get_tree().create_timer(1.25,false,false,true).timeout
		get_tree().create_tween().tween_property(waiting, "position:y", 700, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		waiting.hide()

func _on_login_pressed() -> void:
	var email_checks = [".org", ".com"]
	
	var email = $CanvasLayer/Login/Panel/email
	var password = $CanvasLayer/Login/Panel/password
	var error = $CanvasLayer/Login/Panel/Error
	
	var check1 = false
	for check in email_checks:
		if str(email.text).contains("@") and str(email.text).contains(check):
			check1 = true
			break
	if check1 and str(password.text).length() >= 8:
		error.text = "Attempting to login..."
		var response = await GDSync.account_login(str(email.text), str(password.text), 86400)
		var code = response["Code"]
		
		print(code)
		
		if code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.EMAIL_OR_PASSWORD_INCORRECT:
			error.text = "ERROR: Email and/or password could not be found."
		elif code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.BANNED:
			var ban_time = response["BanTime"]
			if ban_time == -1:
				error.text = "ERROR: The account you attempted to login to is permenantly banned."
			else:
				var current_time = Time.get_unix_time_from_system()
				var seconds_left = ban_time - current_time
				
				var days_left = ceil(seconds_left/86400)
				if days_left == 1:
					error.text = "ERROR: The account you attempted to login to is banned for 1 day."
				else:
					error.text = "ERROR: The account you attempted to login to is banned for " + str(days_left).replace(".0", "") + " days."
				
		elif code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.EXPIRED_SESSION:
			error.text = "ERROR: Session is expired."
		elif code == ENUMS.ACCOUNT_LOGIN_RESPONSE_CODE.SUCCESS:
			print("account logged in")
			
			$"../Shop Handler".current_email = str(email.text)
			$"../Shop Handler".current_pass = str(password.text)
			$"../Data Handler".get_items("play lobby, check gifts")
			$"../Data Handler".get_currency()
			waiting.position.y = -700
			waiting.show()
			get_tree().create_tween().tween_property(login, "position:y", 700, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			get_tree().create_tween().tween_property(waiting, "position:y", 0, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await get_tree().create_timer(1.25,false,false,true).timeout
			login.hide()
			signup.hide()
			
			$"../CanvasLayer/Waiting/Panel/task".text = "Loading Data..."
			while not $"../Data Handler".loaded_items: await get_tree().create_timer(0.01).timeout
			
			$"../Lobby".show()
			get_tree().create_tween().tween_property(waiting, "position:y", 700, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			await get_tree().create_timer(0.75,false,false,true).timeout
			waiting.hide()
			
			var info_res = await GDSync.account_document_set("user info", {"email": str(email.text), "password": str(password.text)}, true)
			
			if info_res == ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.SUCCESS:
				print("successfully set user info.")
			else:
				print("error setting user info: ", ENUMS.ACCOUNT_DOCUMENT_SET_RESPONSE_CODE.keys()[info_res])
	else:
		if not check1:
			error.text = "ERROR: The provided email is not valid."
		if str(password.text).length() < 8:
			error.text = "ERROR: Password is not at least 8 characters."

func _on_make_pressed() -> void:
	login.hide()
	signup.show()

func _on_back_pressed() -> void:
	login.show()
	signup.hide()
