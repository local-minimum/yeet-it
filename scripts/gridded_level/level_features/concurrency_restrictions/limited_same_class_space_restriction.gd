extends OccupancyConcurrencyRestriction
class_name LimitedSameClassSpaceRestriction

@export var max_coinhabitants: int = 4

func can_coexist(entity: GridEntity, others: Array[GridEntity]) -> bool:
    if others.size() >= max_coinhabitants:
        return false

    var type: EntityFilter.EntityType = EntityFilter.get_entity_type(entity)

    return others.filter(
        func (e: GridEntity) -> bool:
            return type == EntityFilter.get_entity_type(e)
    ).size() == others.size()
