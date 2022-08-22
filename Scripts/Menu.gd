extends Control


onready var iPAddress = $IPAddress
onready var buttonHost = $ButtonHost
onready var buttonConnect = $ButtonConnect
onready var labelStatus = $LabelStatus

export (NodePath) var select_skin_path
onready var select_skin = get_node(select_skin_path)

func _ready():
	randomize()
	get_tree().connect("network_peer_connected", self, "_connected")
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
	var game = preload("res://Scenes/Level_0.tscn").instance()
	
	get_tree().get_root().add_child(game)
	Singleton.current_level = game
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
	if Singleton.current_level != null:
		# Erase immediately, otherwise network might show
		# errors (this is why we connected deferred above)
		Singleton.current_level.queue_free()
		Singleton.current_level = null
		show()

	get_tree().set_network_peer(null) # Remove peer.
	buttonHost.set_disabled(false)
	buttonConnect.set_disabled(false)

	_set_status(with_error, false)


func _on_select_skin_item_selected(index):
	Singleton.current_skin = index


func _on_UserName_text_changed(new_text):
	Singleton.nickname = new_text
