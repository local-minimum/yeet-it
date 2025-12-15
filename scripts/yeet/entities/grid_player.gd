extends GridPlayerCore
class_name GridPlayer

@export var max_health: int = 24
@export var health: int = 24

@export var caster: RayCast3D
@export var body_center_forward_ray: RayCast3D


func hurt(amount: int) -> void:
    if amount <= 0:
        push_error("Cannot hurt negative amount or zero")
        return

    var previous_health: int = health
    health = maxi(0, health - amount)

    __SignalBus.on_hurt_entity.emit(self, previous_health, health, max_health)

    if health == 0:
        kill()


func kill() -> void:
    super.kill()
    __SignalBus.on_kill_entity.emit(self)
