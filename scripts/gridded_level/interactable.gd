extends Node3D
class_name Interactable

@export var _debug: bool
@export var _collission_shape: CollisionShape3D

var physics_body: PhysicsBody3D:
    get():
        if _collission_shape == null:
            return null
        return _collission_shape.get_parent() as PhysicsBody3D
        
var is_interactable: bool = true:
    set(value):
        is_interactable = value
        if value:
            __SignalBus.on_allow_interactions.emit(self)
        else:
            __SignalBus.on_disallow_interactions.emit(self)

var _hovered: bool
var _showing_cursor_hand: bool

func _enter_tree() -> void:
    var body: PhysicsBody3D = physics_body
    if body == null:
        return
    if (
        !body.mouse_entered.is_connected(_on_static_body_3d_mouse_entered) &&
        body.mouse_entered.connect(_on_static_body_3d_mouse_entered) != OK
    ):
        push_warning("Failed to connect mouse entered body")
    
    if (
        !body.mouse_exited.is_connected(_on_static_body_3d_mouse_exited) &&
        body.mouse_exited.connect(_on_static_body_3d_mouse_exited) != OK
    ):
        push_warning("Failed to connect mouse exited body")       

    if (
        !body.input_event.is_connected(_on_static_body_3d_input_event) &&
        body.input_event.connect(_on_static_body_3d_input_event) != OK
    ):
        push_warning("Failed to connect body input event")
        
func _exit_tree() -> void:
    is_interactable = false
    
    var body: PhysicsBody3D = physics_body  
    if body != null:
        body.mouse_entered.disconnect(_on_static_body_3d_mouse_entered)
        body.mouse_exited.disconnect(_on_static_body_3d_mouse_exited)
        body.input_event.disconnect(_on_static_body_3d_input_event)
        
func player_is_in_range() -> bool:
    return _in_range(_collission_shape.global_position)

func bounding_box() -> AABB:
    var size: Vector3 = Vector3.ONE

    if _collission_shape.shape is BoxShape3D:
        var box: BoxShape3D = _collission_shape.shape
        size = global_basis * box.size

    elif _collission_shape.shape is SphereShape3D:
        var sphere: SphereShape3D = _collission_shape.shape
        size = global_basis * (sphere.radius * Vector3i.ONE)
    else:
        push_warning("Collision shape %s type not handled" % _collission_shape.shape)

    return AABB(_collission_shape.global_position - size * 0.5, size)

## Determines if player should be presented with it as an interaction option
func _in_range(_event_position: Vector3) -> bool:
    return true

## Determines if when interacting, it should be allowed or refused
func check_allow_interact() -> bool:
    return true

func execute_interation() -> void:
    pass

func _on_static_body_3d_input_event(
    _camera: Node,
    event: InputEvent,
    event_position: Vector3,
    _normal: Vector3,
    _shape_idx: int,
) -> void:
    if !is_interactable:
        return

    if _in_range(event_position):
        if !_showing_cursor_hand:
            if _debug:
                print_debug("[Interactable %s] Showing cursor hand" % self)
            InputCursorHelper.add_state(self, InputCursorHelper.State.HOVER)
            _showing_cursor_hand = true
    else:
        if _showing_cursor_hand:
            if _debug:
                print_debug("[Interactable %s] Return to cursor arrow" % self)
            InputCursorHelper.remove_state(self, InputCursorHelper.State.HOVER)
            _showing_cursor_hand = false

        return

    if event is InputEventMouseButton && !event.is_echo():
        var mouse_event: InputEventMouseButton = event

        if mouse_event.pressed && mouse_event.button_index == MOUSE_BUTTON_LEFT:
            if check_allow_interact():
                execute_interation()

func _on_static_body_3d_mouse_entered() -> void:
    _hovered = true
    InputCursorHelper.add_state(self, InputCursorHelper.State.HOVER)
    if is_interactable && _in_range(_collission_shape.global_position):
        if _debug:
            print_debug("[Interactable %s] Showing cursor hand (entered)" % self)
        _showing_cursor_hand = true

func _on_static_body_3d_mouse_exited() -> void:
    _hovered = false
    _showing_cursor_hand = false
    InputCursorHelper.remove_state(self, InputCursorHelper.State.HOVER)
    if _debug:
        print_debug("[Interactable %s] Showing cursor arrow (exit)" % self)
