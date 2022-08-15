extends KinematicBody


const SPEED = 3
const JUMP = 8
const GRAVITY = 0.3
const ROTATE = 0.05

var y_pos = 0

func _ready():
	pass

remote func _set_pos(position, rotation, scale):
	global_transform.origin = position
	global_rotation = rotation
	global_scale(scale)

func _physics_process(delta):	
	if is_network_master():
		var moving_vec = Vector3()
		if Input.is_action_pressed("player_forward"):		
			moving_vec.z -= 1
		if Input.is_action_pressed("player_backward"):
			moving_vec.z += 1
		if Input.is_action_pressed("player_right"):
			rotate_y(-ROTATE)
		if Input.is_action_pressed("player_left"):
			rotate_y(ROTATE)
		if Input.is_action_pressed("player_jump"):
			moving_vec.y += 1
			
		moving_vec = moving_vec.normalized() * SPEED
	
		move_and_slide(transform.basis.xform(Vector3(0, y_pos, moving_vec.z)), Vector3.UP)
		#move_and_slide(moving_vec, Vector3.UP)
		rpc_unreliable("_set_pos", global_transform.origin, get_global_rotation(), get_scale())
	
		if is_on_floor():
			if Input.is_action_pressed("player_jump"):
				y_pos = JUMP
			else:
				y_pos = -0.5
		else:
			y_pos -= GRAVITY
		
		# shooting plates
		if Input.is_action_just_pressed("attack"):
			#var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			print("attacking!")
			print(get_global_transform())
			
