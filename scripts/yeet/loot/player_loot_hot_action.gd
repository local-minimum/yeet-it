extends Node
class_name PlayerLootHotAction

@export var hot_key_index: int
@export var hot_key_label: Label
@export var loot_slot_ui: LootContainerSlotUI
@export var throw_lateral_offset: float = 0.5
@export var throw_target_default_distance: float = 4
@export var throw_max_target_distance: float = 12
@export var target_search_distance_max: int = 3
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

    if projectile is LootProjectile && _level != null && _level.player is GridPlayer:
        var body: LootProjectile = projectile
        _throw_body(body, loot, _level.player as GridPlayer)
    else:
        push_error("[Hot Action %s] Instanced %s:s world object is not a loot projectile %s" % [hot_key_index, loot_slot_ui.loot_slot.summarize(), projectile])
        if projectile != null:
            projectile.queue_free()

    _animate_cooldown()

func _throw_body(body: LootProjectile, loot: Loot, player: GridPlayer) -> void:
    # Adding as child has to be after global postion set and before launching!
    _level.add_child(body)
    _throw_late.call_deferred(body, loot, player)

func _throw_late(body: LootProjectile, loot: Loot, player: GridPlayer) -> void:
    var player_right: CardinalDirections.CardinalDirection = CardinalDirections.yaw_cw(player.look_direction, player.down)[0]
    body.global_position = player.center.global_position + CardinalDirections.direction_to_vector(player_right) * throw_lateral_offset

    var target: Vector3 = _get_throw_target(player)

    body.name = loot.id
    body.launch(loot.tags, (target - body.global_position).normalized())


func _get_throw_target(player: GridPlayer) -> Vector3:
    var entity_target: GridEntity = _find_entity_target(player)
    if entity_target != null:
        print_debug("[Hot Key %s] Found entity target %s" % [hot_key_index, entity_target])
        return entity_target.center.global_position

    # Throw something forward in general
    var ray_origin: Vector3 = player.center.global_position
    var ray_direction: Vector3 = CardinalDirections.direction_to_vector(player.look_direction) * throw_target_default_distance
    var target: Vector3 = ray_origin + ray_direction * throw_target_default_distance

    var caster: RayCast3D = player.body_center_forward_ray
    caster.target_position = caster.to_local(target)
    caster.force_raycast_update()
    if caster.is_colliding():
        print_debug("[Hot Action %s] Found default target in %s at %s" % [hot_key_index, player.caster.get_collider(), caster.get_collision_point()])
        return caster.get_collision_point()

    return target

func _find_entity_target(player: GridPlayer) -> GridEntity:
    if _level == null:
        push_warning("[Hot Action %s] We're not in a level!" % [hot_key_index])
        return

    var options: Array[GridEntity]

    var caster: RayCast3D = player.caster
    var coords: Vector3i = player.coordinates()
    var idx: int = 0
    while idx < target_search_distance_max:
        # Get next position
        coords = CardinalDirections.translate(coords, player.look_direction)

        print_debug("[Hot Action %s] Looking for entities at %s" % [hot_key_index, coords])
        for entity: GridEntity in _level.grid_entities:

            if entity is GridEnemy && entity.coordinates() == coords:
                var enemy: GridEnemy = entity
                if !enemy.is_alive():
                    continue
                caster.target_position = player.caster.to_local(enemy.center.global_position)
                caster.force_raycast_update()
                if caster.is_colliding():
                    var collider: Object = caster.get_collider() #c.get("collider", null)
                    if collider is Node:
                        if GridEntity.find_entity_parent(collider as Node, true) == entity:
                            options.append(entity)
                            print_debug("[Hot Action %s] Entity %s can be traced with ray" % [hot_key_index, entity.name])
                        else:
                            print_debug("[Hot Action %s] %s in the way of throwing stuff at %s" % [
                                hot_key_index,
                                collider,
                                enemy,
                            ])
                    else:
                        push_error("[Hot Action %s] Collsion with non node %s!" % [hot_key_index, collider])

        if !options.is_empty():
            return options.pick_random()

        idx += 1

    return null

func _animate_cooldown() -> void:
    cooldown_overlay.show()
    await get_tree().create_timer(float(_next_throw_msec - Time.get_ticks_msec()) / 1000.0).timeout
    cooldown_overlay.hide()
