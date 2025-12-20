extends RigidBody3D
class_name LootProjectile

@export var throw_speed: float = 10

## Only applies if launched with tag thin
@export var angular_speed: float = 1

## Dictates how long the item can be flying
@export var max_flight_duration: float = 2

const crash_bounce_fudge_angle: float = 0.5
const crash_energy_scale: float = 0.005
const crash_gravity_scale: float = 1.25

func _on_body_entered(body: Node) -> void:
    if _crashed:
        return

    print_debug("[Loot Projectile %s] Smacked into %s of %s" % [name, body, body.get_parent()])
    var entity: GridEntity = GridEntity.find_entity_parent(body, true)
    if entity is GridEnemy:
        var enemy: GridEnemy = entity
        enemy.take_hit(_tags)

    gravity_scale = crash_gravity_scale

    if _in_contact:
        var contact_position: Vector3 = to_global(_contact_center)
        var impulse_direction: Vector3 = _contact_center.normalized() * -1
        impulse_direction = VectorUtils.apply_random_rotation_to_direction(impulse_direction, crash_bounce_fudge_angle)

        # TODO: This doesn't make sense but hey decent enough
        var energy: float = 0.5 * mass * throw_speed # pow(throw_speed, 2)
        print_debug("[Loot Projectile %s] Gains impulse based on %s energy applied at %s in %s direction" % [
            name,
            energy,
            contact_position,
            impulse_direction,
        ])
        apply_impulse(impulse_direction * energy * crash_energy_scale, contact_position)
    crash()

var _in_contact: bool
var _contact_center: Vector3
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    var c: int = state.get_contact_count()

    if c < 1:
        _in_contact = false
        return

    var target: Node = null
    var points: int = 0

    for idx: int in range(c):
        var obj: Object = state.get_contact_collider_object(idx)
        if obj is Node and (target == null || obj == target):
            target = obj

            if points == 0:
                _contact_center = state.get_contact_local_position(idx)
            else:
                _contact_center += state.get_contact_local_position(idx)

            points += 1

    if points > 1:
        _contact_center /= points

    if !_crashed:
        print_debug("[Loot Projectile %s] Integrate forces with %s contact points against %s at %s" % [name, points, target, _contact_center])

    if target != null:
        _in_contact = true
        _on_body_entered(target)


var _tags: Array[Loot.Tag]

func launch(tags: Array[Loot.Tag], direction: Vector3) -> void:
    _tags = tags

    # print_debug("[Loot Projectile %s] Launching at %s with velocity %s" % [name, global_position, direction * throw_speed])
    linear_velocity = direction * throw_speed

    if tags.has(Loot.Tag.Thin):
        angular_velocity = Vector3(0, angular_speed, 0)

    await get_tree().create_timer(max_flight_duration).timeout
    if !_crashed:
        gravity_scale = crash_gravity_scale
        await get_tree().create_timer(1).timeout

        crash()

var _crashed: bool
func crash() -> void:
    if _crashed:
        return

    _crashed = true
    print_debug("[Loot Projectile %s] Crashing!" % [name])
    await get_tree().create_timer(0.5).timeout
    linear_damp = 10
    angular_damp = 30

    await get_tree().create_timer(10).timeout
    print_debug("[Loot Projectile %s] Freeing" % [name])
    queue_free()
