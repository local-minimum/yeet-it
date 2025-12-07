extends Control
class_name DraggedLoot

@export var icon: TextureRect
@export var count_label: Label
@export var offset: Vector2
@export var tween_back_speed: float = 0.5

func _enter_tree() -> void:
    if __SignalBus.on_drag_loot_start.connect(_handle_drag_loot_start) != OK:
        push_error("Failed to connect to drag start")

    if __SignalBus.on_drag_loot.connect(_handle_drag_loot) != OK:
        push_error("Failed to connect to drag")

    if __SignalBus.on_drag_loot_end.connect(_handle_drag_loot_end) != OK:
        push_error("Failed to connect to drag end")

func _exit_tree() -> void:
    __SignalBus.on_drag_loot_start.disconnect(_handle_drag_loot_start)
    __SignalBus.on_drag_loot.disconnect(_handle_drag_loot)
    __SignalBus.on_drag_loot_end.disconnect(_handle_drag_loot_end)

func _ready() -> void:
    hide()

func _handle_drag_loot_start(slot_ui: LootContainerSlotUI) -> void:
    if slot_ui == null || slot_ui.is_empty:
        hide()
        return

    _sync(slot_ui)
    show()

func _sync(slot_ui: LootContainerSlotUI) -> void:
    icon.texture = slot_ui.loot_slot.loot.ui_texture
    count_label.text = ("%s" % slot_ui.loot_slot.count) if slot_ui.loot_slot.count > 1 else ""

func _handle_drag_loot_end(slot_ui: LootContainerSlotUI, origin: Vector2) -> void:
    var distance: float = origin.distance_to(global_position)
    if slot_ui.is_empty || distance < 1:
        slot_ui.show_content()
        hide()
        return

    _sync(slot_ui)
    var tween: Tween = create_tween()
    @warning_ignore_start("return_value_discarded")
    tween.tween_property(self, "global_position", origin, distance / tween_back_speed)
    @warning_ignore_restore("return_value_discarded")

    if tween.finished.connect(func () -> void:
        slot_ui.show_content()
        hide()
    ) != OK:
        push_error("Failed to connect to finished on tween")

        slot_ui.show_content()
        hide()




func _handle_drag_loot(_slot_ui: LootContainerSlotUI, mouse_position: Vector2) -> void:
    global_position = mouse_position + offset
    # global_position = get_global_mouse_position() + offset
