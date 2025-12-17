extends RigidBody3D
class_name LootProjectile

@export var throw_speed: float = 10

## Only applies if launched with tag thin
@export var angular_speed: float = 1

## Dictates how long the item can be flying
@export var max_flight_duration: float = 2

func _on_body_entered(body: Node) -> void:
    print_debug("[Loot Projectile %s] Smacked into %s of %s" % [name, body, body.get_parent()])
    var entity: GridEntity = GridEntity.find_entity_parent(body, true)
    if entity is GridEnemy:
        var enemy: GridEnemy = entity
        enemy.take_hit(_tags)
    crash()

var _tags: Array[Loot.Tag]

func launch(tags: Array[Loot.Tag], direction: Vector3) -> void:
    _tags = tags

    linear_velocity = direction * throw_speed

    if tags.has(Loot.Tag.Thin):
        angular_velocity = Vector3(0, angular_speed, 0)

    await get_tree().create_timer(max_flight_duration).timeout
    gravity_scale = 5
    await get_tree().create_timer(1).timeout
    crash()

var _crashed: bool
func crash() -> void:
    if _crashed:
        return

    _crashed = true
    print_debug("[Loot Projectile %s] Crashing!" % [name])
    await get_tree().create_timer(0.5).timeout
    print_debug("[Loot Projectile %s] Freeing" % [name])
    queue_free()
