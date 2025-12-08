extends Control

@export var slot_scene: PackedScene
@export var container_icon: TextureRect
@export var container_name: Label
@export var slots_root: Control
@export var delay_time: float = 0.4

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

func _get_slot_ui(idx: int) -> LootContainerSlotUI:
    if idx < _slots.size():
        return _slots[idx]

    var ui: LootContainerSlotUI = slot_scene.instantiate()

    ui.name = "Slot container %s" % idx
    _slots.append(ui)
    slots_root.add_child(ui)

    return ui

func _hide_slots_from(idx: int) -> void:
    for ui: LootContainerSlotUI in _slots.slice(idx):
        ui.loot_slot = null

func _handle_quick_tranfer_loot(from: LootContainerSlotUI) -> void:
    if _paused:
        return

    print_debug("[Loot Container UI %s] Processing quick transfer of %s" % [name, from])
    if from.is_empty:
        push_warning("[Loot Container UI %s] Quick transfer of nothing should not happen" % name)
        return

    if visible && !_slots.has(from):
        for slot: LootContainerSlotUI in _slots:
            if slot.is_empty:
                slot.swap_loot_with(from)
                return

        for slot: LootContainerSlotUI in _slots:
            if slot.loot_slot.loot == from.loot_slot.loot:
                if slot.fill_up_with_loot_from(from):
                    if from.is_empty:
                        break
    else:
        print_debug("[Loot Container UI %s] %s not for me because visible=%s or my slot %s" % [
            name, from, visible, _slots.has(from),
        ])

func _handle_open_container(loot_container: LootContainer) -> void:
    _container = loot_container
    container_icon.texture = loot_container.ui_icon
    container_name.text = loot_container.localized_name

    _hide_slots_from(0)
    show()

    var idx: int = 0
    for slot: LootSlot in loot_container.slots:
        await get_tree().create_timer(delay_time).timeout

        var ui: LootContainerSlotUI = _get_slot_ui(idx)
        ui.loot_slot = slot
        idx += 1

func _on_close_loot_ui_btn_pressed() -> void:
    if _paused:
        return

    var container: LootContainer = _container
    print_debug("[Loot Container UI %s] Executing close code for container %s" % [name, container])

    _container = null
    hide()

    __SignalBus.on_close_container.emit(container)
