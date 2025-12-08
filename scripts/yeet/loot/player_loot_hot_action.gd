extends Node
class_name PlayerLootHotAction

@export var hot_key_index: int
@export var hot_key_label: Label
@export var loot_slot_ui: LootContainerSlotUI
@export var throw_lateral_offset: float = 0.5
@export var throw_target_default_distance: float = 4
@export var cooldown_overlay: Control

func _enter_tree() -> void:
    if __SignalBus.on_level_loaded.connect(_handle_level_loaded) != OK:
        push_error("Could not connect to level loaded")
    if __SignalBus.on_level_unloaded.connect(_handle_level_unloaded) != OK:
        push_error("Could not connect to level unloaded")
    if loot_slot_ui != null && loot_slot_ui.on_slot_clicked.connect(_handle_slot_click) != OK:
        push_error("Could not connect to slot click")
    cooldown_overlay.hide()

func _exit_tree() -> void:
    __SignalBus.on_level_loaded.disconnect(_handle_level_loaded)
    __SignalBus.on_level_unloaded.disconnect(_handle_level_unloaded)
    if is_instance_valid(loot_slot_ui):
        loot_slot_ui.on_slot_clicked.disconnect(_handle_slot_click)

var _level: GridLevelCore

func _handle_slot_click(slot: LootContainerSlotUI) -> void:
    if _may_do_action && !slot.is_empty:
        _enact_throw()

func _handle_level_loaded(level: GridLevelCore) -> void:
    _level = level

func _handle_level_unloaded(level: GridLevelCore) -> void:
    if _level == level:
        _level = null

var _may_do_action: bool:
    get():
        return _level != null && !_level.paused && !_level.player == null && !_level.player.cinematic

func _unhandled_input(event: InputEvent) -> void:
    if _may_do_action:
        if event.is_action_pressed(InteractionUI.get_key_id(hot_key_index)):
            # TODO: Cooldown
            if loot_slot_ui.is_empty:
                _warn_nothing_to_throw()
            else:
                _enact_throw()
        return

func _warn_nothing_to_throw() -> void:
    print_debug("[Loot Hot Key %s Action] Trying to throw nothing!" % [hot_key_index])

var _cooldown_start_msec: int
var _next_throw_msec: int

func _enact_throw() -> void:
    if Time.get_ticks_msec() < _next_throw_msec:
        return

    var loot: Loot = loot_slot_ui.loot_slot.loot
    _cooldown_start_msec = Time.get_ticks_msec()
    _next_throw_msec = _cooldown_start_msec + roundi(loot.cooldown * 1000)

    print_debug("[Loot Hot Key %s Action] Throwing %s" % [hot_key_index, loot_slot_ui.loot_slot.loot.id])
    var projectile: Node = loot_slot_ui.loot_slot.loot.world_model.instantiate()
    loot_slot_ui.loot_slot.count -= 1
    loot_slot_ui.sync_slot()

    if projectile is LootProjectile:
        var body: LootProjectile = projectile
        _throw_body(body, loot)
    else:
        push_error("[Hot Action %s] Instanced loot '%s':s world object is not a loot projectile %s" % [hot_key_index, loot_slot_ui.loot_slot.loot.id, projectile])
        projectile.queue_free()

    _animate_cooldown()

func _throw_body(body: LootProjectile, loot: Loot) -> void:
    _level.add_child(body)
    var player: GridPlayerCore = _level.player
    var player_right: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(player.look_direction, player.down)[0]
    body.global_position = player.center.global_position + CardinalDirections.direction_to_vector(player_right) * throw_lateral_offset
    var target: Vector3 = player.center.global_position + CardinalDirections.direction_to_vector(player.look_direction) * throw_target_default_distance
    body.launch(loot.tags, (target - body.global_position).normalized())

func _animate_cooldown() -> void:
    cooldown_overlay.show()
    await get_tree().create_timer(float(_next_throw_msec - Time.get_ticks_msec()) / 1000.0).timeout
    cooldown_overlay.hide()
