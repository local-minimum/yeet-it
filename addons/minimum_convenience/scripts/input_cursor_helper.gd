class_name InputCursorHelper

enum State { HOVER, DRAG }

static var _hovered: Array[Node]
static var _dragged: Array[Node]

static func add_state(node: Node, state: State) -> void:
    match state:
        State.HOVER:
            if !_hovered.has(node):
                _hovered.append(node)
        State.DRAG:
            if !_dragged.has(node):
                _dragged.append(node)

    _sync_cursor()

static func remove_state(node: Node, state: State) -> void:
    match state:
        State.HOVER:
            _hovered.erase(node)
        State.DRAG:
            _dragged.erase(node)

    _sync_cursor()


static func _sync_cursor() -> void:
    if !_dragged.is_empty():
        Input.set_default_cursor_shape(Input.CURSOR_DRAG)
    elif !_hovered.is_empty():
        Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
    else:
        Input.set_default_cursor_shape(Input.CURSOR_ARROW)
