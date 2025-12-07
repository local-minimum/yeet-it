extends Control
class_name LootContainerSlotUI

@export var _show_as_dragging_sq_dist: float =  10.0

@export var _count_label: Label
@export var _item_texture: TextureRect
@export var _content_root: Control

var loot_slot: LootSlot:
    set(value):
        loot_slot = value
        _sync_slot()

func _sync_slot() -> void:
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
        return loot_slot == null || loot_slot.loot == null || loot_slot.count < 1

static var _hovered: LootContainerSlotUI
static var _dragged: LootContainerSlotUI
static var _drag_origin: Vector2
static var _shown_as_dragging: bool

func _on_mouse_entered() -> void:
    print_debug("[Slot UI %s] Hover enter" % name)
    _hovered = self
    InputCursorHelper.add_state(self, InputCursorHelper.State.HOVER)


func _on_mouse_exited() -> void:
    print_debug("[Slot UI %s] Hover exit" % name)
    InputCursorHelper.remove_state(self, InputCursorHelper.State.HOVER)

    if _hovered == self:
        _hovered = null


var _active_slot: bool:
    get():
        return _hovered == self || _dragged == self


func show_content() -> void:
    _content_root.show()

func _on_gui_input(event: InputEvent) -> void:
    if event.is_echo() || !_active_slot:
        return

    if event is InputEventMouseButton:
        var m_button: InputEventMouseButton = event
        if m_button.button_index == MOUSE_BUTTON_LEFT:
            if m_button.is_pressed():
                _dragged = self
                _drag_origin = _content_root.global_position
                _shown_as_dragging = false
            else:
                var self_was_dragged: bool = _dragged == self

                if _dragged == null:
                    push_warning("[Interactable %s] Nothing dragged, so can't recieve anything" % name)
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

func _return_dragged_to_origin() -> void:
    print_debug("[Slot UI %s] Return dragged loot" % [name])
    _dragged = null

func _adopt_dragged_loot() -> void:
    print_debug("[Slot UI %s] Adopt dragged loot from %s" % [name, _dragged])
    if _dragged.loot_slot == null || _dragged.loot_slot.count < 1:
        _dragged = null

    if loot_slot.loot == null || loot_slot.count < 1:
        _swap_loot_with(_dragged)
    elif loot_slot.loot == _dragged.loot_slot.loot:
        var stackable: int = maxi(0, loot_slot.loot.stack_size - loot_slot.count)
        if stackable > 0:
            var transfer_count: int = mini(stackable, _dragged.loot_slot.count)
            loot_slot.count += transfer_count
            _dragged.loot_slot.count -= transfer_count
            _sync_slot()
            _dragged._sync_slot()
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
            _swap_loot_with(_dragged)
    else:
        _swap_loot_with(_dragged)

    _dragged = null

func _swap_loot_with(other: LootContainerSlotUI) -> void:
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
    _sync_slot()

    other.loot_slot.loot = my_loot
    if my_loot != null:
        other.loot_slot.count = my_count
    other._sync_slot()

    print_debug("[Slot UI %s] After swapping %s with %s %s" % [
        self.name,
        self.loot_slot.summarize(),
        other.name,
        other.loot_slot.summarize(),
    ])
