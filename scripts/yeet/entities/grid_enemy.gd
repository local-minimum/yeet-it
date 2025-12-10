extends GridEnemyCore
class_name GridEnemy

## Max health
@export var _max_health: int = 100
## Current / start health
@export var _health: int = 100

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

func hurt(amount: int = 1) -> void:
    _health = maxi(0, _health - amount)
    print_debug("[Grid Enemy %s] Hurt for %s (health now %s)" % [name, amount, _health])
    if _health == 0:
        kill()

func kill() -> void:
    _health = 0
    visible = false
    cause_cinematic(self)

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

func _handle_move_end(entity: GridEntity) -> void:
    if entity == self:
        _next_move_allowed_time = roundi(_after_walk_wait * 1000.0) + Time.get_ticks_msec()
