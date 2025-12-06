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
