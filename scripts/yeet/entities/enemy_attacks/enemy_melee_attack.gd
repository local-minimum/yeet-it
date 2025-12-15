extends EnemyAttack
class_name EnemyMeleeAttack

@export var _reach: int = 1
@export var _require_facing: bool = true

@export var _base_damage: int = 1
@export var _var_damage: int = 4
@export var _crit_chance: float = 0.02
@export var _crit_multiplier: float = 2

func can_target(target: GridEntity) -> bool:
    return target is GridPlayerCore

func calculate_hurt(_target: GridEntity) -> int:
    if randf() < _crit_chance:
        return ceili(_base_damage + _crit_multiplier * _var_damage)

    return _base_damage + randi_range(0, _var_damage)

func in_range(attacker: GridEnemy, target_coordinates: Vector3i) -> bool:
    var coordinates: Vector3i = attacker.coordinates()
    if _require_facing:
        for _idx: int in range(_reach):
            coordinates = CardinalDirections.translate(coordinates, attacker.look_direction)
            if coordinates == target_coordinates:
                return true
        return false

    return VectorUtils.manhattan_distance(coordinates, target_coordinates) < _reach
