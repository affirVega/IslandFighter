extends RigidBody


func _ready():
	pass


func _on_RigidBody_body_exited(body):
	# игрок когда создаёт бутылку добавляет себя в исключения. нужно убрать исключение
	# когда бутылка покидает хитбокс игрока
	remove_collision_exception_with(body)
