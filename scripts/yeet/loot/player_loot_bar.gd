extends Control

@export var ui_slots: Array[LootContainerSlotUI]

func _enter_tree() -> void:
    _setup_slots()

func _setup_slots() -> void:
    for ui: LootContainerSlotUI in ui_slots:
        ui.loot_slot = LootSlot.new()
