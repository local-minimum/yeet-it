extends Interactable
class_name LootContainer

var _level: GridLevelCore
var _max_distance_sq: float = 2.5

## Used for look up of
@export var category_id: String
@export var ui_icon: Texture2D
@export var slots: Array[LootSlot]

var localized_name: String:
    get():
        return tr("CONTAINER_%s_NAME" % category_id.to_upper())

var player: GridPlayerCore:
    get():
        return _level.player if _level != null else null

func _enter_tree() -> void:
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

func _in_range(_event_position: Vector3) -> bool:
    var p: GridPlayerCore = player

    return (
        p!= null &&
        !p.cinematic &&
        p.free_look == GridPlayerCore.FreeLookMode.INACTIVE &&
        global_position.distance_squared_to(p.center.global_position) < _max_distance_sq &&
        p.camera.is_position_in_frustum(global_position)
    )

func check_allow_interact() -> bool:
    return true

func execute_interation() -> void:
    # _level.player.cause_cinematic(self)
    __SignalBus.on_open_container.emit(self)
