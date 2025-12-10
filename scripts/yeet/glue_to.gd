extends Node3D
class_name GlueTo

@export var _other: Node3D

var _offset: Vector3

func _ready() -> void:
    _offset = _other.to_local(global_position)

func _physics_process(_delta: float) -> void:
    global_position = _other.to_global(_offset)
    global_basis = _other.global_basis
