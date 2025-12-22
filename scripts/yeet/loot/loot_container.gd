extends Interactable
class_name LootContainer

var _level: GridLevelCore
@export var _interact_min_distance_sq: float = 0.0
@export var _interact_max_distance_sq: float = 2.5

## Used for look up of
@export var category_id: String
@export var ui_icon: Texture2D
@export var slots: Array[LootSlot]
@export var container_as_loot: Loot

var slots_revealed: int

var localized_name: String:
    get():
        return tr("CONTAINER_%s_NAME" % category_id.to_upper().strip_edges().replace(" ", "_"))

var player: GridPlayerCore:
    get():
        return _level.player if _level != null else null

func _enter_tree() -> void:
    if __SignalBus.on_level_loaded.connect(_handle_level_loaded) != OK:
        push_error("Failed to connect to level loaded")
    if __SignalBus.on_level_unloaded.connect(_handle_level_unloaded) != OK:
        push_error("Failed to connect to level unloaded")
    if __SignalBus.on_close_container.connect(_handle_close_container) != OK:
        push_error("Failed to connect to close container")

func _exit_tree() -> void:
    __SignalBus.on_level_loaded.disconnect(_handle_level_loaded)
    __SignalBus.on_level_unloaded.disconnect(_handle_level_unloaded)
    __SignalBus.on_close_container.disconnect(_handle_close_container)

    var p: GridPlayerCore = player
    if p != null && p.cinematic:
        p.remove_cinematic_cause(self)

    super._exit_tree()

func _ready() -> void:
    is_interactable = true

func _handle_level_unloaded(level: GridLevelCore) -> void:
    if _level == level:
        _level = null

func _handle_level_loaded(level: GridLevelCore) -> void:
    _level = level

func _handle_close_container(container: LootContainer) -> void:
    var p: GridPlayerCore = player

    if container == self && p != null:
        p.remove_cinematic_cause(self)
        if _debug:
            print_debug("[Loot Container %s] Closed myself, player %s is now cinematic=%s" % [
                p.name,
                name,
                p.cinematic,
            ])

func _in_range(_event_position: Vector3) -> bool:
    var p: GridPlayerCore = player
    var d: float = global_position.distance_squared_to(p.center.global_position)
    if _debug:
        print_debug("[Loot Container %s] In Range of %s: cinematic %s / looking %s == %s/ distance sq %s < %s / in frustrum %s" % [
            name,
            p,
            p.cinematic,
            GridPlayerCore.FreeLookMode.find_key(p.free_look),
            GridPlayerCore.FreeLookMode.find_key(GridPlayerCore.FreeLookMode.INACTIVE),
            d,
            _interact_max_distance_sq,
            p.camera.is_position_in_frustum(global_position)
        ])
    return (
        p!= null &&
        !p.cinematic &&
        p.free_look == GridPlayerCore.FreeLookMode.INACTIVE &&
        d > _interact_min_distance_sq &&
        d < _interact_max_distance_sq &&
        p.camera.is_position_in_frustum(global_position)
    )

func check_allow_interact() -> bool:
    return true

func execute_interation() -> void:
    var p: GridPlayerCore = player
    if p != null:
        p.cause_cinematic(self)

    __SignalBus.on_open_container.emit(self)

func remove_container() -> void:
    visible = false
    is_interactable = false
    NodeUtils.disable_physics_in_children(self)
