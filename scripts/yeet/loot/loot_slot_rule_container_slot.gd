extends LootSlotRuleset
class_name LootSlotRuleContainerSlot

var _container: LootContainerUI

func _init(container: LootContainerUI) -> void:
    _container = container

func accepts(_own: LootContainerSlotUI, other: LootSlot) -> bool:
    if other != _container.contaier_as_loot_slot.loot_slot:
        return true

    print_debug("[Loot Rule Container] Refuse content from %s because it is my own container" % [other])
    return false
