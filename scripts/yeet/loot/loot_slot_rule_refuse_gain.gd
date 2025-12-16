extends LootSlotRuleset
class_name LootSlotRuleRefuseGain

func accepts(_own: LootContainerSlotUI, other: LootContainerSlotUI) -> bool:
    if other == null || other.is_empty:
        return true

    print_debug("[Gain Rule] I refuse because other %s tries to give me shit %s" % [
        other,
        other.loot_slot.summarize(),
    ])
    return false
