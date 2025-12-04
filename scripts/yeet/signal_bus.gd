extends SignalBusCore
class_name SignalBus

@warning_ignore_start("unused_signal")

# Loot
signal on_open_container(container: LootContainer)
signal on_close_container(container: LootContainer)

@warning_ignore_restore("unused_signal")
