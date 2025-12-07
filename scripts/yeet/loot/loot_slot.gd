extends Resource
class_name LootSlot

@export var loot: Loot:
    set(value):
        loot = value
        if value == null && count > 0:
            count = 0

@export var count: int:
    set(value):
        if value == 0 && count != 0 && loot != null:
            count = max(0, value)
            loot = null
        else:
            count = max(0, value)

func summarize() -> String:
    if loot == null || count < 1:
        return "<EMPTY>"

    return "<%s %s>" % [count, loot.id]
