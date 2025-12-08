extends Control

@export var ui_slots: Array[LootContainerSlotUI]

func _enter_tree() -> void:
    _setup_slots()
    if __SignalBus.on_quick_transfer_loot.connect(_handle_quick_tranfer_loot) != OK:
        push_error("Failed to connect to quick transfer loot")

func _exit_tree() -> void:
    __SignalBus.on_quick_transfer_loot.disconnect(_handle_quick_tranfer_loot)

func _setup_slots() -> void:
    for ui: LootContainerSlotUI in ui_slots:
        ui.loot_slot = LootSlot.new()

func _handle_quick_tranfer_loot(from: LootContainerSlotUI) -> void:
    if from.is_empty:
        return

    if visible && !ui_slots.has(from):
        for slot: LootContainerSlotUI in ui_slots:
            if slot.is_empty:
                slot.swap_loot_with(from)
                return

        for slot: LootContainerSlotUI in ui_slots:
            if slot.loot_slot.loot == from.loot_slot.loot:
                if slot.fill_up_with_loot_from(from):
                    if from.is_empty:
                        break
