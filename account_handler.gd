extends Node

func _on_signup_pressed() -> void:
	var email_checks = [".org", ".com"]
	
	var email = $CanvasLayer/Signup/Panel/email
	var user = $CanvasLayer/Signup/Panel/username
	var password = $CanvasLayer/Signup/Panel/password
	
	var check1 = false
	for check in email_checks:
		if str(email.text).contains("@") and str(email.text).contains(check):
			check1 = true
			break

	var check2 = false
	if str(password.text).length() >= 8:
		check2 = true
		
	var check3 = false
	if str(user.text).length() >= 3: # change to use ENUM check to check for taken username
		check3 = true
	
	if check1 and check2 and check3:
		GDSync.account_create(str(email.text), str(user.text), str(password.text))

func _on_login_pressed() -> void:
	pass # Replace with function body.
