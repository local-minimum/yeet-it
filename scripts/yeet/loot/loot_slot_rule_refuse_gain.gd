extends LootSlotRuleset
class_name LootSlotRuleRefuseGain

func accepts(_own: LootContainerSlotUI, other: LootSlot) -> bool:
    if other == null || other.empty:
        return true

    print_debug("[Gain Rule] I refuse because other %s tries to give me shit %s" % [
        other,
        other.summarize(),
    ])
    return false
