extends Control
class_name HealthBar


@export var anim_bar: ProgressBar
@export var health_bar: ProgressBar
@export var _anim_duration: float = 0.5

var _level: GridLevelCore
var _tween: Tween

func _enter_tree() -> void:
    if __SignalBus.on_level_loaded.connect(_handle_level_loaded) != OK:
        push_error("Failed to connect to level loaded")
    if __SignalBus.on_level_unloaded.connect(_handle_level_unloaded) != OK:
        push_error("Failed to connect to level unloaded")
    if __SignalBus.on_hurt_entity.connect(_handle_entity_hurt) != OK:
        push_error("Failed to connect to hurt entity")

    anim_bar.max_value = 100
    anim_bar.value = 0
    health_bar.max_value = 100
    health_bar.value = 0

func _exit_tree() -> void:
    __SignalBus.on_level_loaded.disconnect(_handle_level_loaded)
    __SignalBus.on_level_unloaded.disconnect(_handle_level_unloaded)
    __SignalBus.on_hurt_entity.disconnect(_handle_entity_hurt)


func _handle_entity_hurt(entity: GridEntity, previous_health: int, health: int, max_health: int) -> void:
    if _level == null:
        return

    if entity == _level.player:
        health_bar.max_value = max_health
        health_bar.value = health

        anim_bar.max_value = max_health

        var duration: float = _anim_duration

        if _tween == null || !_tween.is_running():
            anim_bar.value = previous_health
            _tween = create_tween()
        else:
            duration += _anim_duration - _tween.get_total_elapsed_time()
            _tween.kill()
            _tween = create_tween()

        @warning_ignore_start("return_value_discarded")
        _tween.tween_property(anim_bar, "value", health, duration).set_trans(Tween.TRANS_SINE)
        @warning_ignore_restore("return_value_discarded")

func _handle_level_loaded(level: GridLevelCore) -> void:
    _level = level
    if _level.player is GridPlayer:
        var player: GridPlayer = _level.player
        health_bar.max_value = player.max_health
        health_bar.value = player.health
        anim_bar.max_value = player.max_health
        anim_bar.value = player.health

func _handle_level_unloaded(level: GridLevelCore) -> void:
    if _level == level:
        _level = null
