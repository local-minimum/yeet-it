extends Node
class_name PlayerLootHotAction

@export var hot_key_index: int
@export var hot_key_label: Label
@export var loot_slot_ui: LootContainerSlotUI

func _enter_tree() -> void:
    if __SignalBus.on_level_loaded.connect(_handle_level_loaded) != OK:
        push_error("Could not connect to level loaded")
    if __SignalBus.on_level_unloaded.connect(_handle_level_unloaded) != OK:
        push_error("Could not connect to level unloaded")

func _exit_tree() -> void:
    __SignalBus.on_level_loaded.disconnect(_handle_level_loaded)
    __SignalBus.on_level_unloaded.disconnect(_handle_level_unloaded)

var _level: GridLevelCore

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
            if loot_slot_ui.is_empty:
                print_debug("[Loot Hot Key %s Action] Trying to throw nothing!" % [hot_key_index])
            else:
                print_debug("[Loot Hot Key %s Action] Throwing %s" % [hot_key_index, loot_slot_ui.loot_slot.loot.id])
        return
