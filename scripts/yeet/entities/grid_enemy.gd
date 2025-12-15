extends GridEnemyCore
class_name GridEnemy

## Max health
@export var _max_health: int = 100
## Current / start health
@export var _health: int = 100

@export var attack: EnemyAttack

@export var _base_damage_per_hit: int = 10
@export var _stagger_chance_factor: float = 1
@export var _stagger_duration: float = 0.5
@export var _after_walk_wait: float = 0.1

@export_group("Animations")
@export var _animator: AnimationPlayer
@export var _anim_idle: String = "Idle"
@export var _anim_stagger: String = "Stagger"


var _next_move_allowed_time: int:
    set(value):
        _next_move_allowed_time = value
        _informed_move_allowed = false

var _informed_move_allowed: bool

func _enter_tree() -> void:
    if __SignalBus.on_move_end.connect(_handle_move_end) != OK:
        push_error("Failed to connect to move end")

func _exit_tree() -> void:
    __SignalBus.on_move_end.disconnect(_handle_move_end)

func _ready() -> void:
    super._ready()

    _health = mini(_health, _max_health)
    if _animator != null:
        _animator.play(_anim_idle)

    _watched_nodes = GridNode.flood_fill_awareness_area(get_grid_node(), look_direction)

func _process(_delta: float) -> void:
    if !is_alive() || cinematic || Time.get_ticks_msec() < _next_move_allowed_time:
        return

    if _do_attack():
        return

    _next_move_allowed_time = roundi(_after_walk_wait * 1000.0) + Time.get_ticks_msec()
    if _move_target != null:
        var offset: Vector3i = _move_target.coordinates - coordinates()
        var direction: CardinalDirections.CardinalDirection = CardinalDirections.principal_direction(offset)
        var move: Movement.MovementType = Movement.from_directions(direction, look_direction, down)
        if direction != look_direction && CardinalDirections.is_planar_orthogonal(direction, down, look_direction):
            if direction == CardinalDirections.invert(look_direction):
                move = Movement.MovementType.TURN_CLOCKWISE if randf() < 0.5 else Movement.MovementType.TURN_COUNTER_CLOCKWISE
            else:
                var yaw: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(look_direction, down)[0]

                if yaw == direction:
                    move = Movement.MovementType.TURN_CLOCKWISE
                else:
                    yaw = CardinalDirections.yaw_ccw(look_direction, down)[0]
                    if yaw == direction:
                        move = Movement.MovementType.TURN_COUNTER_CLOCKWISE

        if !force_movement(move):
            push_warning("[Grid Enemy %s] Failed to enforce movement %s" % [name, Movement.name(move)])

func _do_attack() -> bool:
    if is_moving() || attack == null || _move_target == null || !attack.in_range(self, _move_target.coordinates):
        return false

    var targets: Array[GridEntity] = Array(
        get_level().grid_entities.filter(
            func (e: GridEntity) -> bool:
                return e != self && attack.can_target(e) && attack.in_range(self, e.coordinates())),
        TYPE_OBJECT,
        "Node3D",
        GridEntity,
    )

    if targets.is_empty():
        return false

    print_debug("[Grid Enemy %s] Attacking %s with %s" % [self, targets, attack])
    attack.execute_on(targets)
    _next_move_allowed_time = Time.get_ticks_msec() + attack.cooldown_msec

    return true



func hurt(amount: int = 1) -> void:
    var previous_health: int = _health
    _health = maxi(0, _health - amount)
    print_debug("[Grid Enemy %s] Hurt for %s (health now %s)" % [name, amount, _health])
    __SignalBus.on_hurt_entity.emit(self, previous_health, _health, _max_health)

    if _health == 0:
        kill()

func kill() -> void:
    _health = 0
    visible = false
    cause_cinematic(self)
    occupying_space = false
    __SignalBus.on_kill_entity.emit(self)

func is_alive() -> bool:
    return _health > 0

func take_hit(tags: Array[Loot.Tag]) -> void:
    # TODO: Add real logic somewhere!
    var damage: float = _base_damage_per_hit

    for tag: Loot.Tag in tags:
        if tag == Loot.Tag.Heavy:
            damage *= 1.5

    var stagger: bool = randf_range(0, _max_health) < damage * _stagger_chance_factor
    if stagger:
        print_debug("[Grid Enemy %s] Staggered" % name)

        if _animator != null:
            _animator.play(_anim_stagger)

        _next_move_allowed_time = roundi(_stagger_duration * 1000.0) + Time.get_ticks_msec()

    hurt(roundi(damage))

var _move_target: GridNode
var _watched_nodes: Array[GridNode]

func _handle_move_end(entity: GridEntity) -> void:
    if entity == self:
        _next_move_allowed_time = roundi(_after_walk_wait * 1000.0) + Time.get_ticks_msec()
        _watched_nodes = GridNode.flood_fill_awareness_area(get_grid_node(), look_direction)
        if entity.get_grid_node() == _move_target:
            _move_target = null
    elif entity == get_level().player:
        var player_node: GridNode = entity.get_grid_node()
        if _watched_nodes.has(player_node):
            _move_target = player_node
