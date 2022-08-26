extends RigidBody


func _ready():
	# ставим чтобы RigitBody издавал сигнал при сталвиваниях
	contact_monitor = true
	
	# ставим максимальное количество контактов за раз
	contacts_reported = 4


func _on_RigidBody_body_entered(body):
	if body is PhysicsBody:
		if body.is_in_group("Player"):
			body.hit()
	queue_free()
