extends KinematicBody

export (PackedScene) var bottle_scene

const SPEED = 3
const JUMP = 8
const GRAVITY = 0.3
const ROTATE = 0.05

const THROW_ANGLE_DEGREES = 30
const THROW_FORCE = 5

var SKIN_OBJECTS = {}

var y_pos = 0

func _ready():
	SKIN_OBJECTS = {
		GV.COOLDOG: $Skins/cooldog,
		GV.LOW3: $Skins/low3,
		GV.MAKSVELL: $Skins/maksvell,
		GV.MIKA: $Skins/mikamoro,
		GV.S1TN4M: $Skins/s1tn4m,
	}

	if is_network_master():
		set_skin(Singleton.current_skin)
		rpc('set_skin', Singleton.current_skin)

remote func set_skin(index: int):
	for skin in SKIN_OBJECTS.values():
		skin.visible = false
	assert(index in SKIN_OBJECTS, 'передан невалидный индекс скина')
	SKIN_OBJECTS[index].visible = true

remote func _set_pos(position, rotation, scale):
	global_transform.origin = position
	global_rotation = rotation
	global_scale(scale)

remote func make_bottle(position: Vector3, impulse: Vector3):
	#var bottle: RigidBody = bottle_scene.instance()
	var bottle: RigidBody = preload("res://Player/Bottle.tscn").instance()
	bottle.transform.origin = position
	bottle.add_collision_exception_with(self) # игнорируем игрока который бросает
	bottle.apply_central_impulse(impulse) # добавляем импульс
	get_tree().root.add_child(bottle)

func _physics_process(delta):
	if not is_network_master():
		return
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
		
		#var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var spawn_pos = global_transform.origin + Vector3(0, 0.2, 0)
		
		var impulse: Vector3 = Vector3.FORWARD
		var angle = THROW_ANGLE_DEGREES / 180.0 * PI
		impulse = impulse.rotated(Vector3.RIGHT, angle) # поворачиваем наверх
		impulse = impulse.rotated(Vector3.UP, rotation.y) # поворачиваем в бок
		impulse = impulse.normalized() * THROW_FORCE # нормализируем и применяем силу броску
		
		make_bottle(spawn_pos, impulse)
		rpc("make_bottle", spawn_pos, impulse)
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		rpc('set_skin', Singleton.current_skin)
