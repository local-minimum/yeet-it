extends LootContainer
class_name LootContainerCorpse

@export var corpse_root: Node3D
@export var world_slots: Array[LootSlotWorld]

func _ready() -> void:
    super._ready()
    is_interactable = false

func remove_container() -> void:
    super.remove_container()
    if corpse_root != null:
        corpse_root.hide()
        disable_physics_in_children(corpse_root)

func get_world_slot(slot: LootSlot) -> LootSlotWorld:
    for world_slot: LootSlotWorld in world_slots:
        if world_slot.slot == slot:
            return world_slot
    return null
