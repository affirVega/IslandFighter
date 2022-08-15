extends Node2D

onready var iPAddress = $IPAddress
onready var buttonHost = $ButtonHost
onready var buttonConnect = $ButtonConnect
onready var labelStatus = $LabelStatus

func _ready():
	get_tree().connect("network_peer_connected", self, "_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	


func _on_ButtonHost_pressed():
	var server = NetworkedMultiplayerENet.new()
	var err = server.create_server(3456, 2)
	
	if err != OK:
		_set_status("Не могу подключиться к серверу по данному IP.", false)
		return
	get_tree().set_network_peer(server)
	buttonHost.set_disabled(true)
	buttonConnect.set_disabled(true)
	_set_status("Ожидание второго игрока...", true)


func _on_ButtonConnect_pressed():	
	var client = NetworkedMultiplayerENet.new()
	var ip = iPAddress.get_text()
	client.create_client(ip, 3456)	
	get_tree().set_network_peer(client) # Replace with function body.
	_set_status("Поиск сервера...", true)

func _connected(client_id):
	Singleton.user_id = client_id
	var game = preload("res://Scenes/Main.tscn").instance()
	get_tree().get_root().add_child(game)
	hide()

func _set_status(text, isok):
	# Simple way to show status.
	if isok:
		labelStatus.set_text(text)
		labelStatus.set("custom_colors/font_color", Color(0.498039, 1, 0, 1))
	else:
		labelStatus.set_text(text)
		labelStatus.set("custom_colors/font_color", Color( 0.862745, 0.0784314, 0.235294, 1))

func _connected_fail():
	_set_status("Сбой подключения", false)

	get_tree().set_network_peer(null) # Remove peer.
	buttonConnect.set_disabled(false)
	buttonHost.set_disabled(false)
	
	
func _connected_ok():	
	_set_status("Подключение к серверу...", true) # This function is not needed for this project.
	
	
func _player_disconnected(_id):
	if get_tree().is_network_server():
		_end_game("Связь с игроком разорвана")
	else:
		_end_game("Связь с сервером разорвана")

func _server_disconnected():
	_end_game("Сервер разорвал соединение")
	
	
func _end_game(with_error = ""):
	if has_node("/root/Menu"):
		# Erase immediately, otherwise network might show
		# errors (this is why we connected deferred above).
		get_node("/root/Menu").free()
		show()

	get_tree().set_network_peer(null) # Remove peer.
	buttonHost.set_disabled(false)
	buttonConnect.set_disabled(false)

	_set_status(with_error, false)
