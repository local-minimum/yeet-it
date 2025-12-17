extends Control

func _enter_tree() -> void:
    if __SignalBus.on_open_container.connect(_handle_container_open) != OK:
        push_error("Failed to connect container open")
    if __SignalBus.on_close_container.connect(_handle_container_close) != OK:
        push_error("Failed to connect conainer close")
    if __SignalBus.on_drag_loot_start.connect(_handle_drag_loot_start) != OK:
        push_error("Failed to connect drag loot start")
    if __SignalBus.on_drag_loot_end.connect(_handle_drag_loot_end) != OK:
        push_error("Failed to connect drag loot end")

func _exit_tree() -> void:
    __SignalBus.on_open_container.disconnect(_handle_container_open)
    __SignalBus.on_close_container.disconnect(_handle_container_close)
    __SignalBus.on_drag_loot_start.disconnect(_handle_drag_loot_start)
    __SignalBus.on_drag_loot_end.disconnect(_handle_drag_loot_end)

var _dragged_lot: LootContainerSlotUI
var _open_conatiner: LootContainer
var _hovered: bool

var needed: bool:
    get():
        return _dragged_lot != null || _open_conatiner != null

func _handle_container_open(container: LootContainer) -> void:
    if container != null:
        _open_conatiner = container

        _enable_trash_area()

func _handle_container_close(container: LootContainer) -> void:
    if _open_conatiner == container:
        _open_conatiner = null

        if !needed:
            _disable_trash_area()


func _handle_drag_loot_start(slot_ui: LootContainerSlotUI) -> void:
    if slot_ui != null && !slot_ui.is_empty:
        _dragged_lot = slot_ui

        _enable_trash_area()

func _handle_drag_loot_end(slot_ui: LootContainerSlotUI, _origin: Vector2) -> void:
    if _dragged_lot == slot_ui:
        _dragged_lot = null

        if _hovered:
            print_debug("[Trashbin] Trashing %s" % [slot_ui.loot_slot.summarize()])
            slot_ui.loot_slot.count = 0
            slot_ui.sync_slot()

        if !needed:
            _disable_trash_area()

func _ready() -> void:
    _disable_trash_area()

func _disable_trash_area() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hovered = false

func _enable_trash_area() -> void:
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP

func _on_mouse_exited() -> void:
    _hovered = false

func _on_mouse_entered() -> void:
    _hovered = true
