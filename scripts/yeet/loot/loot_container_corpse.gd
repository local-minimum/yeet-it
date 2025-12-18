extends LootContainer
class_name LootContainerCorpse

@export var world_slots: Array[LootSlotWorld]

func _ready() -> void:
    super._ready()
    is_interactable = false
