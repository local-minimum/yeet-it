extends Control
class_name LootContainerSlotUI

@export var _count_label: Label
@export var _item_texture: TextureRect

var loot_slot: LootSlot:
    set(value):
        if value == null:
            hide()
        elif value.loot == null:
            _count_label.text = ""
            _item_texture.texture = null
            tooltip_text = ""
            show()
        else:
            _count_label.text = ("%s" % value.count) if value.count > 1 else ""
            _item_texture.texture = value.loot.ui_texture
            tooltip_text = value.loot.localized_name
            show()
        loot_slot = value

static var _hovered: LootContainerSlotUI
static var _dragged: LootContainerSlotUI

func _on_mouse_entered() -> void:
    print_debug("[Slot UI %s] Hover enter" % name)
    _hovered = self
    Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
    print_debug("[Slot UI %s] Hover exit" % name)
    if _hovered == self:
        _hovered = null
        Input.set_default_cursor_shape(Input.CURSOR_ARROW)


var _active_slot: bool:
    get():
        return _hovered == self || _dragged == self

func _on_gui_input(event: InputEvent) -> void:
    if event.is_echo() || !_active_slot:
        return

    if event is InputEventMouseButton:
        var m_button: InputEventMouseButton = event
        if m_button.button_index == MOUSE_BUTTON_LEFT:
            if m_button.is_pressed():
                _dragged = self
            else:
                if _dragged == self && (_hovered == null || _hovered == self):
                    _return_dragged_to_origin()
                elif _hovered != null:
                    _hovered._adopt_dragged_loot()

func _return_dragged_to_origin() -> void:
    print_debug("[Slot UI %s] Return dragged loot" % [name])

func _adopt_dragged_loot() -> void:
    print_debug("[Slot UI %s] Adopt dragged loot from %s" % [name, _dragged])
