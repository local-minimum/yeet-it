extends Resource
class_name LootSlot

signal on_slot_content_updated()

@export var loot: Loot:
    set(value):
        var updated: bool = loot != value
        loot = value
        if value == null && count > 0:
            count = 0
        elif updated:
            on_slot_content_updated.emit()

@export var count: int:
    set(value):
        if value == 0 && count != 0 && loot != null:
            count = max(0, value)
            loot = null
        else:
            var updated: bool = count != max(0, value)
            count = max(0, value)
            if updated:
                on_slot_content_updated.emit()

var empty: bool:
    get():
        return loot == null || count < 1

func summarize() -> String:
    if loot == null || count < 1:
        return "<EMPTY>"

    return "<%s %s>" % [count, loot.id]
