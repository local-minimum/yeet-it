extends OccupancyConcurrencyRestriction
class_name NoConcurrencyRestriction

func can_coexist(_entity: GridEntity, _others: Array[GridEntity]) -> bool:
    return true
