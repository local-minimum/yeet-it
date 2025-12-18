extends Control
class_name LootContainerUI

@export var slot_scene: PackedScene
@export var container_icon: TextureRect
@export var container_name: Label
@export var slots_root: Control
@export var delay_time: float = 0.4
@export var contaier_as_loot_slot: LootContainerSlotUI

var _slots: Array[LootContainerSlotUI]
var _container: LootContainer
var _paused: bool = false

func _enter_tree() -> void:
    hide()
    if __SignalBus.on_open_container.connect(_handle_open_container) != OK:
        push_error("Failed to connect to open container")
    if __SignalBus.on_quick_transfer_loot.connect(_handle_quick_tranfer_loot) != OK:
        push_error("Failed to connect to quick transfer loot")
    if __SignalBus.on_level_pause.connect(_handle_level_pause) != OK:
        push_error("Failed to connect to level pause")
    if contaier_as_loot_slot != null && contaier_as_loot_slot.on_slot_updated.connect(_handle_slot_updated) != OK:
        push_error("Failed to connect slot updated")

func _exit_tree() -> void:
    __SignalBus.on_open_container.disconnect(_handle_open_container)
    __SignalBus.on_quick_transfer_loot.disconnect(_handle_quick_tranfer_loot)
    __SignalBus.on_level_pause.disconnect(_handle_level_pause)

func _unhandled_input(event: InputEvent) -> void:
    if _paused:
        return

    if visible && event.is_action_pressed("ui_cancel"):
        print_debug("[Loot Container UI %s] Closing with ui cancel pressed" % name)
        _on_close_loot_ui_btn_pressed()

func _handle_level_pause(_level: GridLevelCore, paused: bool) -> void:
    _paused = paused

func _get_slot_ui(idx: int, locked: bool = false) -> LootContainerSlotUI:
    var ui: LootContainerSlotUI = null
    if idx < _slots.size():
        ui = _slots[idx]
    else:
        ui = slot_scene.instantiate()
        ui.name = "Slot container %s" % idx
        _slots.append(ui)
        slots_root.add_child(ui)

        if ui.on_slot_updated.connect(_handle_slot_updated) != OK:
            push_error("Failed to connect slot updated")

    ui._ruleset = (LootSlotRuleRefuseGain.new() as LootSlotRuleset) if locked else LootSlotRuleContainerSlot.new(self)

    return ui

var _updating_slots: bool
func _hide_slots_from(idx: int) -> void:
    _updating_slots = true
    for ui: LootContainerSlotUI in _slots.slice(idx):
        ui.loot_slot = null
    _updating_slots = false

func _handle_quick_tranfer_loot(from: LootContainerSlotUI) -> void:
    if _paused:
        return

    print_debug("[Loot Container UI %s] Processing quick transfer of %s" % [name, from])
    if from.is_empty:
        push_warning("[Loot Container UI %s] Quick transfer of nothing should not happen" % name)
        return

    if visible && !_slots.has(from) && from != contaier_as_loot_slot:
        for slot: LootContainerSlotUI in _slots:
            if slot.loot_slot.loot == from.loot_slot.loot:
                if slot.fill_up_with_loot_from(from):
                    if from.is_empty:
                        return

        for slot: LootContainerSlotUI in _slots:
            if slot.is_empty:
                slot.swap_loot_with(from)
                return
    else:
        print_debug("[Loot Container UI %s] %s not for me because visible=%s or my slot %s" % [
            name, from, visible, _slots.has(from),
        ])

func _handle_open_container(loot_container: LootContainer) -> void:
    _container = loot_container
    container_icon.texture = loot_container.ui_icon
    container_name.text = loot_container.localized_name


    _hide_slots_from(0)
    _updating_slots = true
    show()

    var idx: int = 0
    var has_content: bool
    if loot_container is LootContainerCorpse:
        var corpse_container: LootContainerCorpse = loot_container
        for world_slot: LootSlotWorld in corpse_container.world_slots:
            var ui: LootContainerSlotUI = _get_slot_ui(idx, true)
            ui.delay_reveal(world_slot.slot, delay_time * (idx + 1))
            idx += 1
            has_content = has_content || !world_slot.slot.empty

    for slot: LootSlot in loot_container.slots:
        var ui: LootContainerSlotUI = _get_slot_ui(idx)
        ui.delay_reveal(slot, delay_time * (idx + 1))
        idx += 1
        has_content = has_content || !slot.empty

    _config_container_as_loot(loot_container.container_as_loot, !has_content)
    await get_tree().create_timer(delay_time * idx).timeout
    _updating_slots = false
    _handle_slot_updated(null)

func _handle_slot_updated(updade_slot: LootContainerSlotUI) -> void:
    if _updating_slots == true:
        return

    if updade_slot == contaier_as_loot_slot && updade_slot != null && updade_slot.is_empty:
        if _container != null:
            _container.remove_container()
        _on_close_loot_ui_btn_pressed()
        return

    if _container is LootContainerCorpse && updade_slot != null && updade_slot.is_empty:
        var corpse: LootContainerCorpse = _container
        var world_slot: LootSlotWorld = corpse.get_world_slot(updade_slot.loot_slot)
        if world_slot != null:
            world_slot.hide()

    _sync_container_empty(_slots.all(func (slot: LootContainerSlotUI) -> bool: return slot.is_empty))

func _config_container_as_loot(loot: Loot, empty: bool) -> void:
    contaier_as_loot_slot.create_lootslot(loot)
    _sync_container_empty(empty)

func _sync_container_empty(empty: bool) -> void:
    contaier_as_loot_slot.interactable = empty
    contaier_as_loot_slot.tooltip_text = tr("HINT_CONTAINER_PICKUP" if empty else "HINT_CONTAINER_EMPTY_FIRST")

func _on_close_loot_ui_btn_pressed() -> void:
    if _paused:
        return

    var container: LootContainer = _container
    print_debug("[Loot Container UI %s] Executing close code for container %s" % [name, container])

    _container = null
    hide()

    __SignalBus.on_close_container.emit(container)
