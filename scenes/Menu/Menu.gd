extends Control


onready var iPAddress = $IPAddress
onready var buttonHost = $ButtonHost
onready var buttonConnect = $ButtonConnect
onready var labelStatus = $LabelStatus

export (NodePath) var select_skin_path
onready var select_skin = get_node(select_skin_path)


var players = {}
var my_data = {
	name = 'Player',
	skin_id = 0
}
var current_level = null


func _ready():
	randomize()
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	add_items_skin()


func _process(delta):
	var texture = $Viewport.get_texture()
	$Skins.texture = texture
	$Viewport/skin_preview/skins.rotation.y += 0.01
	#Для дебага по хвосту
	#$Viewport/skin_preview/skins.rotation.y = 8.9
	$Viewport/skin_preview/skins/mikamoro.visible = false
	$Viewport/skin_preview/skins/cooldog.visible = false
	$Viewport/skin_preview/skins/s1tn4m.visible = false
	$Viewport/skin_preview/skins/low3.visible = false


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
	# Создание сервера
	var server = NetworkedMultiplayerENet.new()
	var err = server.create_server(3456, 10)
	
	if err != OK:
		_set_status("Не могу создать сервер на этом порте.", false)
		return
	
	get_tree().set_network_peer(server)
	buttonHost.set_disabled(true)
	buttonConnect.set_disabled(true)
	
	# загружаем уровень
	load_level()
	# создаём своего игрока
	# 1 потому что мы сервер
	var me = instance_player(1)


func _on_ButtonConnect_pressed():
	# Подключение к серверу
	var client = NetworkedMultiplayerENet.new()
	var ip = iPAddress.get_text()
	client.create_client(ip, 3456)	
	get_tree().set_network_peer(client)


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
	# загружаем уровень
	load_level()
	# создаём своего персонажа
	var me = instance_player(get_tree().get_network_unique_id())


func _server_disconnected():
	_end_game("Сервер разорвал соединение")


func _end_game(with_error = ""):
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


func _deferred_stop_scene():
	print('wahooooooooooooooo')
	current_level.queue_free()
	current_level = null


func _on_select_skin_item_selected(index):
	my_data.skin_id = index


func _on_UserName_text_changed(new_text):
	my_data.name = new_text


func load_level():
	var game = preload("res://Scenes/Level_0/Level_0.tscn").instance()
	game.name = 'world'
	get_tree().get_root().add_child(game)
	current_level = game
	hide()


remote func remote_create_player(data):
	var id = get_tree().get_rpc_sender_id()
	# сохраняем данные пользователя. Зачем - не знаю
	players[id] = data
	var player = instance_player(id)


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
