extends Spatial

onready var playerSpawn1 = $PlayerSpawner1
onready var playerSpawn2 = $PlayerSpawner2

var playerScale = Vector3(0.7, 0.7, 0.7)

func _ready():
	var player1 = preload("res://Player/Player.tscn").instance()	
	add_child(player1)
	player1.set_name(str(get_tree().get_network_unique_id()))
	player1.set_network_master(get_tree().get_network_unique_id())
	player1.set_global_transform(playerSpawn1.get_global_transform())	
	print(playerSpawn1.get_global_transform())
	player1.set_scale(playerScale)
	
	var player2 = preload("res://Player/Player.tscn").instance()
	add_child(player2)
	player2.set_name(str(Singleton.user_id))
	player2.set_network_master(Singleton.user_id)
	player2.set_global_transform(playerSpawn2.get_global_transform())
	#print(playerSpawn2.get_global_transform(), "\n")
	player2.set_scale(playerScale) 
