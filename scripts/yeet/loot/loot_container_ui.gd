extends Control

@export var slot_scene: PackedScene
@export var container_icon: TextureRect
@export var container_name: Label
@export var slots_root: Control
@export var delay_time: float = 0.4

var _slots: Array[LootContainerSlotUI]
var _container: LootContainer

func _enter_tree() -> void:
    hide()
    if __SignalBus.on_open_container.connect(_handle_open_container) != OK:
        push_error("Failed to connect to open container")


func _exit_tree() -> void:
    __SignalBus.on_open_container.disconnect(_handle_open_container)
    pass


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
    __SignalBus.on_close_container.emit(_container)
    _container = null
    hide()
