extends RigidBody3D

@onready var og_control = $"og control"
@onready var audio = $sound

var func_completed = false # REQUIRED IN ALL THROWABLES!!!!

func run_function(player: Node3D):
	var control = og_control.duplicate()
	player.add_child(control)
	control.show()
	control.position = Vector2.ZERO
	
	var sprite: AnimatedSprite2D = control.get_node("gif")
	sprite.play()
	audio.play()
	await sprite.animation_finished
	print("func finshed")
	sprite.queue_free()
	control.queue_free()
	func_completed = true
