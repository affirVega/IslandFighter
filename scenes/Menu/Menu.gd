extends Control


const MAX_PLAYERS = 10


onready var iPAddress = $IPAddress
onready var portAddress = $PortAddress
onready var buttonHost = $ButtonHost
onready var buttonConnect = $ButtonConnect
onready var labelStatus = $LabelStatus

export (NodePath) var select_skin_path
onready var select_skin = get_node(select_skin_path)
var SKIN_OBJECTS = {}


var players = {}
var my_data = {
	name = 'Player',
	skin_id = 0,
	text_color = Color.white,
	outline_color = Color.black
}
var current_level = null

var client: WebSocketClient = WebSocketClient.new()
var server: WebSocketServer = WebSocketServer.new()
var is_server = false
var game_started = false

func _ready():
	randomize()
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	add_items_skin()
	
	client.connect("connection_error", self, "_client_disconnected")
	client.connect("connection_closed", self, "_client_disconnected")
	client.connect("connection_failed", self, "_client_disconnected")
	
	SKIN_OBJECTS = {
		GV.COOLDOG: $Viewport/skin_preview/skins/cooldog,
		GV.LOW3: $Viewport/skin_preview/skins/low3,
		GV.MAKSVELL: $Viewport/skin_preview/skins/maksvell,
		GV.MIKA: $Viewport/skin_preview/skins/mikamoro,
		GV.S1TN4M: $Viewport/skin_preview/skins/s1tn4m,
	}
	set_skin_menu(0)
	load_data()

func _client_disconnected(clean=true):
	print('херня отключилассс')


func save_data():
	var settings = {
		ip = $IPAddress.text,
		port = $PortAddress.text,
		name = my_data.name,
		skin_id = my_data.skin_id,
		text_color = my_data.text_color.to_rgba32(),
		outline_color = my_data.outline_color.to_rgba32()
	}
	# записываем настройки в файл
	var file = File.new()
	file.open('user://settings.json', File.WRITE)
	file.store_string(JSON.print(settings))
	file.close()


func load_data():
	# пробуем открыть файл с настройками
	var file: File = File.new()
	var error = file.open('user://settings.json', File.READ)
	if error != OK:
		# не удалось открыть файл
		return
	# пробуем считать JSON оттуда
	var json_result = JSON.parse(file.get_as_text())
	file.close()
	if json_result.error != OK:
		# в файле не JSON
		return
	var settings = json_result.result
	# ставим настройки на место
	$UserName.text = settings.name
	$select_skin.selected = settings.skin_id
	$Color_Text.color = Color(int(settings.text_color))
	$Color_Outline.color = Color(int(settings.outline_color))
	$IPAddress.text = settings.ip
	$PortAddress.text = settings.port
	_on_UserName_text_changed(settings.name)
	_on_select_skin_item_selected(settings.skin_id)
	_on_Color_Text_color_changed(Color(int(settings.text_color)))
	_on_Color_Outline_color_changed(Color(int(settings.outline_color)))


func set_skin_menu(index: int):
	for skin in SKIN_OBJECTS.values():
		skin.visible = false
	assert(index in SKIN_OBJECTS, 'передан невалидный индекс скина')
	SKIN_OBJECTS[index].visible = true


func _process(delta):
	if is_server:
		if server.is_listening():
			server.poll()
	else:
		if client.get_connection_status() == WebSocketClient.CONNECTION_DISCONNECTED:
			client.disconnect_from_host()
			_end_game()
		else:
			client.poll()
	
	var texture = $Viewport.get_texture()
	$Skins.texture = texture
	#$Viewport/skin_preview/skins.rotation.y += 0.01
	$Viewport/skin_preview/skins.rotation_degrees.y += 30*delta
	#Для дебага по хвосту
	#$Viewport/skin_preview/skins.rotation.y = 8.9
	$AudioStreamPlayer.stream_paused = !$CheckButton.pressed
	$AudioStreamPlayer.volume_db = $HSlider.value


func add_items_skin():
	for item in GV.skins:
		select_skin.add_item(item)


func _set_status(text, isok):
	if isok:
		labelStatus.set_text(text)
		labelStatus.set("custom_colors/font_color", Color(0.498039, 1, 0, 1))
	else:
		labelStatus.set_text(text)
		labelStatus.set("custom_colors/font_color", Color( 0.862745, 0.0784314, 0.235294, 1))


func _on_ButtonHost_pressed():
	is_server = true
	# Создание сервера
	var port = int(portAddress.get_text())
	var err = server.listen(port, PoolStringArray(), true)
	
	if err != OK:
		_set_status("Не могу создать сервер на этом порте.", false)
		return
	
	get_tree().set_network_peer(server)
	buttonHost.set_disabled(true)
	buttonConnect.set_disabled(true)
	
	# Выключаем крутящийся скин
	$Viewport/skin_preview.visible = false
	# загружаем уровень
	load_level()
	# создаём своего игрока
	# id сервера всегда 1
	instance_player(1)
	# сохраняем настройки
	save_data()
	game_started = true


func _on_ButtonConnect_pressed():
	is_server = false
	# Подключение к серверу
	var ip = iPAddress.get_text()
	var port = int(portAddress.get_text())
	client.connect_to_url('{0}:{1}'.format([ip,port]), PoolStringArray(), true)	
	get_tree().set_network_peer(client)
	# сохраняем настройки
	save_data()
	game_started = true


func _connection_closed(was_clean: bool):
	print('was clean: ', was_clean)
	_end_game('server disconnected')
	
func _connection_error():
	print('connection error')
	_end_game('server disconnected')


func _player_connected(client_id):
	# когда подключается новый игрок, создаём у него своего игрока
	# потом он создаст у нас своего игрока
	rpc_id(client_id, 'remote_create_player', my_data)


func _player_disconnected(id):
	remove_player(id)


func _connected_fail():
	_set_status("Сбой подключения", false)
	
	# Отключаем сеть
	get_tree().set_network_peer(null)
	buttonConnect.set_disabled(false)
	buttonHost.set_disabled(false)


func _connected_ok():
	# вызывается только у клиентов при успешном подключении
	# Выключаем крутящийся скин
	$Viewport/skin_preview.visible = false
	# загружаем уровень
	load_level()
	# создаём своего персонажа
	instance_player(get_tree().get_network_unique_id())


func _server_disconnected(_clean):
	_end_game("Сервер разорвал соединение")


func _end_game(with_error = ""):
	game_started = false
	if current_level != null:
		# сцена освободится когда все функции завершат работу
		call_deferred("_deferred_stop_scene")
		# показывает интерфейс
		show()
	
	# отключает сеть
	get_tree().set_network_peer(null)
	buttonHost.set_disabled(false)
	buttonConnect.set_disabled(false)

	_set_status(with_error, false)
	$Viewport/skin_preview.visible = true


func _deferred_stop_scene():
	print('wahooooooooooooooo')
	current_level.queue_free()
	current_level = null


func load_level():
	var game = preload("res://scenes/Level_0/Level_1.tscn").instance()
	game.name = 'world'
	get_tree().get_root().add_child(game)
	current_level = game
	# скрывает интерфейс
	hide()


remote func remote_create_player(data):
	var id = get_tree().get_rpc_sender_id()
	# сохраняем данные пользователя. Зачем - не знаю
	players[id] = data
	instance_player(id)


func instance_player(id):
	var player = preload("res://assets/player/Player.tscn").instance()
	player.set_name(str(id))
	player.set_network_master(id)
	get_node("/root/world/players").add_child(player)
	if player.is_network_master():
		player.initialize(my_data)
	else:
		player.initialize(players[id])
	return player


func remove_player(id):
	var target_child: Node = null
	for child in get_node("/root/world/players").get_children():
		if child.get_network_master() == id:
			target_child = child
			break
	
	if target_child != null:
		target_child.queue_free()
	
	if id in players:
		players.erase(id)


func _on_select_skin_item_selected(index):
	my_data.skin_id = index
	set_skin_menu(index)


func _on_UserName_text_changed(nickname):
	my_data.name = nickname
	$Viewport/skin_preview/Nametag_preview.text = nickname


func _on_Color_Text_color_changed(color):
	my_data.text_color = color
	$Viewport/skin_preview/Nametag_preview.modulate = color


func _on_Color_Outline_color_changed(color):
	my_data.outline_color = color
	$Viewport/skin_preview/Nametag_preview.outline_modulate = color
