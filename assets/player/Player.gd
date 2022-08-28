extends KinematicBody

export (PackedScene) var bottle_scene
onready var playerSpawners = null

const SPEED = 160
const JUMP = 8
const GRAVITY = 0.3
const ROTATE = 0.05

const THROW_ANGLE_DEGREES = 30
const THROW_FORCE = 5

var SKIN_OBJECTS = {}

var y_pos = 0
var is_dead = false
var current_skin = null


func _ready():
	playerSpawners = get_node('/root/world/player_spawners')
	SKIN_OBJECTS = {
		GV.COOLDOG: $Skins/cooldog,
		GV.LOW3: $Skins/low3,
		GV.MAKSVELL: $Skins/maksvell,
		GV.MIKA: $Skins/mikamoro,
		GV.S1TN4M: $Skins/s1tn4m,
	}
	set_skin(0)
	
	# спавнимся в рандомной точке
	if is_network_master():
		respawn()


remote func initialize(data):
	set_nickname(data.name)
	set_skin(data.skin_id)
	$Nametag.modulate = data.text_color
	$Nametag.outline_modulate = data.outline_color


remote func set_nickname(new_name: String):
	$Nametag.text = new_name


remote func set_skin(index: int):
	for skin in SKIN_OBJECTS.values():
		skin.visible = false
	assert(index in SKIN_OBJECTS, 'передан невалидный индекс скина')
	SKIN_OBJECTS[index].visible = true
	current_skin = SKIN_OBJECTS[index]


remotesync func _set_pos(position, rotation, scale):
	global_transform.origin = position
	global_rotation = rotation
	global_scale(scale)


remotesync func make_bottle(position: Vector3, impulse: Vector3):
	var bottle: RigidBody = preload("res://assets/throwables/bottle/Bottle.tscn").instance()
	bottle.transform.origin = position
	bottle.add_collision_exception_with(self) # игнорируем игрока который бросает
	bottle.apply_central_impulse(impulse) # добавляем импульс
	get_tree().root.add_child(bottle)


func _physics_process(delta):
	if not is_network_master(): return
	
	var moving_vec = Vector3()
	if not is_dead:
		if Input.is_action_pressed("player_forward"):		
			moving_vec.z -= 1
		if Input.is_action_pressed("player_backward"):
			moving_vec.z += 1
		if Input.is_action_pressed("player_right"):
			rotate_y(-ROTATE)
		if Input.is_action_pressed("player_left"):
			rotate_y(ROTATE)
		
	moving_vec = moving_vec.normalized() * SPEED * delta
	
	if not is_dead:
		if moving_vec == Vector3.ZERO:
			rpc_unreliable("set_animation", "idle", -1, 0.2)
		else:
			rpc_unreliable("set_animation", "run")

	if is_on_floor():
		if Input.is_action_pressed("player_jump") and not is_dead:
			y_pos = JUMP
		else:
			y_pos = -0.5
	else:
		y_pos -= GRAVITY

	move_and_slide(transform.basis.xform(Vector3(0, y_pos, moving_vec.z)), Vector3.UP)
	#move_and_slide(moving_vec, Vector3.UP)
	rpc_unreliable("_set_pos", global_transform.origin, get_global_rotation(), get_scale())
	
	# shooting plates
	if Input.is_action_just_pressed("attack") and not is_dead:
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


remote func hit():
	# эта функция должна вызываться только у владельца объекта
	if not is_network_master(): return
	# если игрок уже умер, не вызыавем повторно
	if is_dead: return
	# вызываем функцию на всех узлах
	rpc('die')


remotesync func die():
	is_dead = true
	# ставим анимацию смерти
	set_animation("die")
	# таймер на три секунды. по истечению времени код продолжится выполняться
	yield(get_tree().create_timer(3), "timeout")
	
	is_dead = false
	# это кривая попытка вернуть игрока в начальное состояние после анимации die
	set_animation("die")
	var animation_player: AnimationPlayer = current_skin.get_node("AnimationPlayer")
	animation_player.seek(0, true)
	animation_player.stop(true)


remotesync func set_animation(animation_name, custom_blend = -1, speed = 1, from_end = false):
	current_skin.get_node("AnimationPlayer").play(animation_name, custom_blend, speed, from_end)


func respawn():
	# выбираем рандомное место спавна
	var random_spawn = playerSpawners.get_child(int(randf() * playerSpawners.get_child_count()))
	set_global_transform(random_spawn.get_global_transform())    
