extends SignalBusCore
class_name SignalBus

@warning_ignore_start("unused_signal")

# Fight
signal on_hurt_entity(entity: GridEntity, previous_health: int, health: int, max_health: int)
signal on_kill_entity(entity: GridEntity)

# Loot
signal on_open_container(container: LootContainer)
signal on_close_container(container: LootContainer)
signal on_drag_loot_start(slot_ui: LootContainerSlotUI)
signal on_drag_loot(slot_ui: LootContainerSlotUI, mouse_position: Vector2)
signal on_drag_loot_end(slot_ui: LootContainerSlotUI, origin: Vector2)
signal on_quick_transfer_loot(from: LootContainerSlotUI)

@warning_ignore_restore("unused_signal")
