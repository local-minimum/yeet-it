@abstract
extends Resource
class_name EnemyAttack

signal on_execute_attack(attack: EnemyAttack, )

@export var cooldown_msec: int = 500

@abstract func can_target(target: GridEntity) -> bool
@abstract func in_range(attacker: GridEnemy, target_coordinates: Vector3i) -> bool
@abstract func calculate_hurt(target: GridEntity) -> int

func execute_on(targets: Array[GridEntity]) -> void:
    for target: GridEntity in targets:
        var hurt: int = calculate_hurt(target)
        if target is GridPlayer:
            var player: GridPlayer = target
            player.hurt(hurt)
        elif target is GridEnemyCore:
            var enemy: GridEnemyCore = target
            enemy.hurt(hurt)
        else:
            push_warning("[Enemy Attack %s] doesn't know how to harm %s" % [self, target])

    on_execute_attack.emit(self)
