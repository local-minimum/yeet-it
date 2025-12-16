extends Control
class_name LootContainerSlotUI

signal on_slot_clicked(slot: LootContainerSlotUI)
signal on_slot_updated(slot: LootContainerSlotUI)

@export var _show_as_dragging_sq_dist: float =  20.0

@export var _count_label: Label
@export var _item_texture: TextureRect
@export var _content_root: Control
@export var _ruleset: LootSlotRuleset

var interactable: bool = true
var _paused: bool

var loot_slot: LootSlot:
    set(value):
        if loot_slot != value:
            if loot_slot != null:
                loot_slot.on_slot_content_updated.disconnect(_handle_loot_slot_content_updated)
            if value != null && value.on_slot_content_updated.connect(_handle_loot_slot_content_updated) != OK:
                push_error("Failed to connect to slot content updated")

            loot_slot = value

            on_slot_updated.emit(self)
        sync_slot()

func sync_slot() -> void:
    if loot_slot == null:
        hide()
    elif loot_slot.loot == null || loot_slot.count < 1:
        _count_label.text = ""
        _item_texture.texture = null
        tooltip_text = ""
        show()
    else:
        _count_label.text = ("%s" % loot_slot.count) if loot_slot.count > 1 else ""
        _item_texture.texture = loot_slot.loot.ui_texture
        tooltip_text = loot_slot.loot.localized_name
        show()

var is_empty: bool:
    get():
        return loot_slot == null || loot_slot.empty

static var _hovered: LootContainerSlotUI
static var _dragged: LootContainerSlotUI
static var _drag_origin: Vector2
static var _shown_as_dragging: bool

func _handle_loot_slot_content_updated() -> void:
    on_slot_updated.emit(self)

func _on_mouse_entered() -> void:
    if _paused:
        return

    if !interactable:
        InputCursorHelper.add_state(self, InputCursorHelper.State.FORBIDDEN)
        return

    print_debug("[Slot UI %s] Hover enter" % name)
    _hovered = self
    if !is_empty:
        InputCursorHelper.add_state(self, InputCursorHelper.State.HOVER)


func _on_mouse_exited() -> void:
    print_debug("[Slot UI %s] Hover exit" % name)
    InputCursorHelper.remove_node(self)

    if _hovered == self:
        _hovered = null

var _active_slot: bool:
    get():
        return _hovered == self || _dragged == self

func create_lootslot(loot: Loot, count: int =  1) -> void:
    loot_slot = LootSlot.new()
    loot_slot.loot = loot
    loot_slot.count = count if count > 0 && loot != null else 0
    sync_slot()

func delay_reveal(slot: LootSlot, delay: float) -> void:
    if slot == null:
        loot_slot = slot
        return

    create_lootslot(null)
    await get_tree().create_timer(delay).timeout
    loot_slot = slot

func show_content() -> void:
    _content_root.show()

func _enter_tree() -> void:
    if __SignalBus.on_level_pause.connect(_handle_level_pause) != OK:
        push_error("Failed to connect to level pause")

func  _exit_tree() -> void:
    __SignalBus.on_level_pause.disconnect(_handle_level_pause)

func _on_gui_input(event: InputEvent) -> void:
    if event.is_echo() || !_active_slot || _paused:
        return

    if event is InputEventMouseButton:
        var m_button: InputEventMouseButton = event
        if m_button.button_index == MOUSE_BUTTON_LEFT:
            if m_button.double_click:
                print_debug("[Slot UI %s] Double click" % [name])
                if !is_empty:
                    __SignalBus.on_quick_transfer_loot.emit(self)
            elif m_button.is_pressed():
                if !is_empty:
                    _dragged = self
                    _drag_origin = _content_root.global_position
                    _shown_as_dragging = false
            elif m_button.is_released() && !_shown_as_dragging:
                if _dragged == self:
                    on_slot_clicked.emit(self)
                    _dragged = null
            else:
                var self_was_dragged: bool = _dragged == self

                if _dragged == null:
                    print_debug("[Slot UI %s] Nothing dragged, so can't recieve anything" % name)
                elif _dragged == self && (_hovered == null || _hovered == self):
                    _return_dragged_to_origin()
                elif _hovered != null:
                    _hovered._adopt_dragged_loot()

                if _shown_as_dragging && self_was_dragged:
                    InputCursorHelper.remove_state(self, InputCursorHelper.State.DRAG)
                    _shown_as_dragging = false
                    __SignalBus.on_drag_loot_end.emit(self, _drag_origin)

    if _dragged == self && event is InputEventMouseMotion:
        var m_motion: InputEventMouseMotion = event
        if !_shown_as_dragging && m_motion.position.distance_squared_to(_drag_origin) > _show_as_dragging_sq_dist:
            _shown_as_dragging = true
            _content_root.hide()
            InputCursorHelper.add_state(self, InputCursorHelper.State.DRAG)
            __SignalBus.on_drag_loot_start.emit(self)

        __SignalBus.on_drag_loot.emit(self, get_global_mouse_position())

func _handle_level_pause(_level: GridLevelCore, paused: bool) -> void:
    _paused = paused

func _return_dragged_to_origin() -> void:
    print_debug("[Slot UI %s] Return dragged loot" % [name])
    _dragged = null

func _adopt_dragged_loot() -> void:
    # print_debug("[Slot UI %s] Adopt dragged loot from %s" % [name, _dragged])
    if _dragged.loot_slot == null || _dragged.loot_slot.count < 1:
        _dragged = null
        return

    if loot_slot.loot == null || loot_slot.count < 1:
        swap_loot_with(_dragged)
    elif loot_slot.loot == _dragged.loot_slot.loot:
        var stackable: int = maxi(0, loot_slot.loot.stack_size - loot_slot.count)
        if stackable > 0 && allowed_transaction(_dragged):
            var transfer_count: int = mini(stackable, _dragged.loot_slot.count)
            loot_slot.count += transfer_count
            _dragged.loot_slot.count -= transfer_count
            sync_slot()
            _dragged.sync_slot()
            if _dragged.loot_slot.count > 0:
                _return_dragged_to_origin()
            else:
                print_debug("[Slot UI %s] Adopted %s from %s resulting in %s and %s" % [
                    name,
                    transfer_count,
                    _dragged.name,
                    loot_slot.summarize(),
                    _dragged.loot_slot.summarize(),
                ])
        else:
            swap_loot_with(_dragged)
    else:
        swap_loot_with(_dragged)

    _dragged = null
    if !is_empty:
        InputCursorHelper.add_state(self, InputCursorHelper.State.HOVER)

func allowed_transaction(other: LootContainerSlotUI) -> bool:
    return _ruleset == null || _ruleset.accepts(self, other)

func fill_up_with_loot_from(other: LootContainerSlotUI) -> bool:
    var stackable: int = maxi(0, loot_slot.loot.stack_size - loot_slot.count)
    if stackable > 0 && allowed_transaction(other):
        var transfer_count: int = mini(stackable, other.loot_slot.count)
        loot_slot.count += transfer_count
        other.loot_slot.count -= transfer_count
        sync_slot()
        other.sync_slot()
        return transfer_count > 0
    return false


func swap_loot_with(other: LootContainerSlotUI) -> void:
    if !allowed_transaction(other) || !other.allowed_transaction(self):
        print_debug("[Slot UI %s] Cannot swap %s with %s because one of us refuses swaps" % [
            self.name,
            self.loot_slot.summarize(),
            other.name
        ])
        _return_dragged_to_origin()
        return

    print_debug("[Slot UI %s] Swapping %s with %s %s" % [
        self.name,
        self.loot_slot.summarize(),
        other.name,
        other.loot_slot.summarize(),
    ])
    var my_loot: Loot = loot_slot.loot
    var my_count: int = loot_slot.count

    loot_slot.loot = other.loot_slot.loot
    loot_slot.count = other.loot_slot.count
    sync_slot()

    other.loot_slot.loot = my_loot
    if my_loot != null:
        other.loot_slot.count = my_count
    other.sync_slot()

    print_debug("[Slot UI %s] After swapping %s with %s %s" % [
        self.name,
        self.loot_slot.summarize(),
        other.name,
        other.loot_slot.summarize(),
    ])
