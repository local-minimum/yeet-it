extends Interactable
class_name FastLootableItem

@export var id: String
@export var loot: LootSlot
@export var exhausted_root: Node3D
@export var _interact_min_distance_sq: float = 2
@export var _interact_max_distance_sq: float = 8

var _level: GridLevelCore
var player: GridPlayerCore:
    get():
        return _level.player if _level != null else null

func _enter_tree() -> void:
    super._enter_tree()
    if __SignalBus.on_level_loaded.connect(_handle_level_loaded) != OK:
        push_error("Failed to connect to level loaded")
    if __SignalBus.on_level_unloaded.connect(_handle_level_unloaded) != OK:
        push_error("Failed to connect to level unloaded")
        
func _exit_tree() -> void:
    __SignalBus.on_level_loaded.disconnect(_handle_level_loaded)
    __SignalBus.on_level_unloaded.disconnect(_handle_level_unloaded)
    
    var p: GridPlayerCore = player
    if p != null && p.cinematic:
        p.remove_cinematic_cause(self)
        
    super._exit_tree()
 
func _ready() -> void:
    is_interactable = false
    
func _handle_level_unloaded(level: GridLevelCore) -> void:
    if _level == level:
        _level = null

func _handle_level_loaded(level: GridLevelCore) -> void:
    _level = level
               
## Determines if player should be presented with it as an interaction option
func _in_range(_event_position: Vector3) -> bool:
    var p: GridPlayerCore = player
    var d: float = _collission_shape.global_position.distance_squared_to(p.center.global_position)
    if _debug:
        print_debug("[Fast Lootable %s] In Range of %s: cinematic %s / looking %s == %s/ distance sq %s < %s < %s / in frustrum %s" % [
            name,
            p,
            p.cinematic,
            GridPlayerCore.FreeLookMode.find_key(p.free_look),
            GridPlayerCore.FreeLookMode.find_key(GridPlayerCore.FreeLookMode.INACTIVE),
            _interact_min_distance_sq,
            d,
            _interact_max_distance_sq,
            p.camera.is_position_in_frustum(_collission_shape.global_position)
        ])
    return (
        p!= null &&
        !p.cinematic &&
        p.free_look == GridPlayerCore.FreeLookMode.INACTIVE &&
        d > _interact_min_distance_sq &&
        d < _interact_max_distance_sq &&
        p.camera.is_position_in_frustum(_collission_shape.global_position)
    )

## Determines if when interacting, it should be allowed or refused
func check_allow_interact() -> bool:
    return true

func execute_interation() -> void:
    if loot.count < 1:
        return
    
    var p: GridPlayerCore = player
    
    p.cause_cinematic(self)
    __SignalBus.on_quick_transfer_loot.emit(null, loot)
    p.remove_cinematic_cause(self)
    
    if loot.count < 1:
        is_interactable = false
        NodeUtils.disable_physics_in_children(exhausted_root)
        exhausted_root.hide()
    elif _debug:
        print_debug("[Fast Lootable %s] Still has %s after looting" % [name, loot.summarize()])
