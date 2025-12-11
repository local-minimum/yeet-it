extends OccupancyConcurrencyRestriction
class_name OnlyOnEntityRestriction

func can_coexist(entity: GridEntity, others: Array[GridEntity]) -> bool:
    return others.is_empty() || others.size() == 1 && others.has(entity)
