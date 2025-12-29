extends RigidBody3D
class_name LootProjectile

@export var _debug: bool
@export var throw_speed: float = 10

## Only applies if launched with tag thin
@export var angular_speed: float = 1

## Dictates how long the item can be flying
@export var max_flight_duration: float = 2

const crash_bounce_fudge_angle: float = 0.5
const crash_energy_scale: float = 0.005
const crash_gravity_scale: float = 1.25

func _enter_tree() -> void:
    if (!body_entered.is_connected(_on_body_entered) && body_entered.connect(_on_body_entered) != OK):
        push_error("Failed to connect body entered")

func _exit_tree() -> void:
    body_entered.disconnect(_on_body_entered)
    
var root: Node3D:
    get():
        var n: Node3D = self
        var steps: int = 0
        while steps < 20:
            var parent: Node = n.get_parent()
            if parent == null || parent is not Node3D:
                return n
            n = parent
            steps += 1
            
        return null
        
func _handle_hit(body: Node) -> void:
    var entity: GridEntity = GridEntity.find_entity_parent(body, true)
    if entity is GridEnemy:
        var enemy: GridEnemy = entity
        enemy.take_hit(_tags)
        return
    
    var destructable: Destructable = Destructable.find_destructable_parent(body, true)
    if destructable != null:
        destructable.take_hit(_tags, global_position)
        return
    
    
func _on_body_entered(body: Node) -> void:
    if _crashed:
        if _debug:
            print_debug("[Loot Projectile %s] Entered %s of %s but already crashed so disregarding" % [name, body, body.get_parent()])
        return

    if _debug:
        print_debug("[Loot Projectile %s] Smacked into %s of %s" % [name, body, body.get_parent()])
    
    _handle_hit(body)
    
    gravity_scale = crash_gravity_scale

    if _in_contact:
        var contact_position: Vector3 = to_global(_contact_center)
        var impulse_direction: Vector3 = _contact_center.normalized() * -1
        impulse_direction = VectorUtils.apply_random_rotation_to_direction(impulse_direction, crash_bounce_fudge_angle)

        # TODO: This doesn't make sense but hey decent enough
        var energy: float = 0.5 * mass * throw_speed # pow(throw_speed, 2)
        if _debug:
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

    if !_crashed && _debug:
        print_debug("[Loot Projectile %s] Integrate forces with %s contact points against %s at %s" % [name, points, target, _contact_center])

    if target != null:
        _in_contact = true
        _on_body_entered(target)


var _tags: Array[Loot.Tag]

func launch(tags: Array[Loot.Tag], direction: Vector3) -> void:
    _tags = tags

    if _debug:
        print_debug("[Loot Projectile %s] Launching at %s with velocity %s" % [name, global_position, direction * throw_speed])
        
    linear_velocity = direction * throw_speed

    if tags.has(Loot.Tag.Thin):
        angular_velocity = Vector3(0, angular_speed, 0)

    if !contact_monitor:
        contact_monitor = true
    
    if max_contacts_reported < 1:
        max_contacts_reported = 2
    
    if !continuous_cd:
        continuous_cd = true
        
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
    if _debug:
        print_debug("[Loot Projectile %s] Crashing!" % [name])
    await get_tree().create_timer(0.5).timeout
    linear_damp = 10
    angular_damp = 30

    await get_tree().create_timer(1.5).timeout
    if _debug:
        print_debug("[Loot Projectile %s] Freeing" % [name])
    queue_free()
