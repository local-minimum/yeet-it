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

var _hovered: bool

func _on_mouse_entered() -> void:
    _hovered = true
    Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
    _hovered = false
    Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_gui_input(event: InputEvent) -> void:
    pass # Replace with function body.
