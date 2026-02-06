extends LineEdit

@onready var button = $togglehide

func _on_togglehide_pressed() -> void:
	if button.text == "Show":
		button.text = "Hide"
		secret = false
	else:
		button.text = "Show"
		secret = true
