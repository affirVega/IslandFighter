extends Spatial

onready var playerSpawners = $player_spawners

# res://Player/Player.tscn
func _ready():
	pass
#	var player1 = preload("res://assets/player/Player.tscn").instance()
#	player1.set_name(str(get_tree().get_network_unique_id()))
#	player1.set_network_master(get_tree().get_network_unique_id())
#
#	var random_spawn = playerSpawners.get_child(int(randf() * playerSpawners.get_child_count()))
#	player1.set_global_transform(random_spawn.get_global_transform())	
#	print(random_spawn.get_global_transform())
#	add_child(player1)
#
#
#	var player2 = preload("res://assets/player/Player.tscn").instance()
#	player2.set_name(str(Singleton.user_id))
#	player2.set_network_master(Singleton.user_id)
#	#player2.set_global_transform(playerSpawn2.get_global_transform())
#	#print(playerSpawn2.get_global_transform(), "\n")
#	add_child(player2)

