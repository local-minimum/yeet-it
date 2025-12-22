extends StaticBody3D
class_name Destructable

const _ANIM_META: String = "Animator"

## If animator is empty looks for "Animator" meta on this node
@export var _animator_holder: Node
@export var _animator: AnimationPlayer:
    get():
        if _animator != null:
            return _animator
        
        if _animator_holder != null && _animator_holder.has_meta(_ANIM_META):
            var path: NodePath = _animator_holder.get_meta(_ANIM_META)
            return _animator_holder.get_node(path)

        return null

@export var health_animation_threshold: Dictionary[int, String]
@export var full_health: int = 100
@export var active_tags: Array[Loot.Tag] = [Loot.Tag.Heavy]
@export var damage_per_tag: int = 15

@export var destructable_geometry: Node3D
@export var destroyed_geometry: Node3D
@export var disable_node_side_on_destroy: GridNodeSide
@export var explosive_force: float = 50

var _health: int
var _current_anim_health: int

func _ready() -> void:
    _health = full_health
    _animate_to_health(_health, true)
    NodeUtils.disable_physics_in_children(destroyed_geometry)
    destroyed_geometry.hide()
    _make_animated_material_unique()
    
const _ANIMATED_MAT: String = "AnimatedMaterial"
const _ANIMATED_MAT_OVERRIDE: String = "AnimatedMaterialOverride"

func _make_animated_material_unique() -> void:
    var anim: AnimationPlayer = _animator
    if anim == null:
        return
    
    if !anim.has_meta(_ANIMATED_MAT):
        return
    var path: NodePath = anim.get_meta(_ANIMATED_MAT)
    var meshinstance: MeshInstance3D = anim.get_node(path)
    if meshinstance == null:
        return
    
    var override: int = -1 if !meshinstance.has_meta(_ANIMATED_MAT_OVERRIDE) else meshinstance.get_meta(_ANIMATED_MAT_OVERRIDE)
    if override < 0:
        for idx: int in range(meshinstance.get_surface_override_material_count()):
            var mat: Material = meshinstance.get_active_material(idx).duplicate()
            meshinstance.set_surface_override_material(idx, mat)
    elif override < meshinstance.get_surface_override_material_count():
        var mat: Material = meshinstance.get_active_material(override).duplicate()
        meshinstance.set_surface_override_material(override, mat)
                   
func take_hit(tags: Array[Loot.Tag], epicenter: Vector3) -> void:
    if _health == 0:
        return
    var dmg: int = tags.filter(func (t: Loot.Tag) -> bool: return active_tags.has(t)).size() * damage_per_tag
    # print_debug("[Destructable %s] Hit with %s cause %s dmg from %s" % [name, tags, dmg, active_tags])
    
    var new_health: int = maxi(0, _health - dmg)
    if new_health > 0:
        _animate_to_health(new_health)
        _health = new_health
    else:
        _health = 0
        NodeUtils.disable_physics_in_children(self)    
            
        if destructable_geometry != null:
            NodeUtils.disable_physics_in_children(destructable_geometry)
            destructable_geometry.hide()
        
        if destroyed_geometry != null:
            destroyed_geometry.show()
            NodeUtils.enable_physics_in_children(destroyed_geometry)
            _explode_destroyd_geometry(epicenter)
            
        if disable_node_side_on_destroy != null:
            disable_node_side_on_destroy.disabled = true
 
func _explode_destroyd_geometry(epicenter: Vector3) -> void:
    for body: RigidBody3D in destroyed_geometry.find_children("", "RigidBody3D"):
        var direction: Vector3 = (body.global_position - epicenter).normalized()
        body.apply_impulse(direction * explosive_force, epicenter)
    
func _animate_to_health(health: int, always_update_value: bool = false) -> void:
    var anim: AnimationPlayer = _animator
    if anim == null:
        print_debug("[Destructable %s] Has no animator" % name)
        if always_update_value:
            _current_anim_health = health
        return
    
    var thresholds: Array[int] = Array(health_animation_threshold.keys(), TYPE_INT, "", "")
    thresholds.sort()
    var idx: int = thresholds.find_custom(func (t: int) -> bool: return t >= health)
    if idx < 0:
        print_debug("[Destrucatble %s] Has no animation threshold for %s %s" % [name, health, health_animation_threshold])
        
        if always_update_value:
            _current_anim_health = health
        return
    
    var anim_health: int = thresholds[idx]
    if anim_health == _current_anim_health && !always_update_value:
        print_debug("[Destrucable %s] Already is at therhold %s for health %s" % [name, _current_anim_health, health])
        return
    
    print_debug("[Destructable %s] animating to '%s' / %s" % [name, health_animation_threshold[anim_health], anim_health])
    anim.play(health_animation_threshold[anim_health])
    _current_anim_health = anim_health
    
static func find_destructable_parent(current: Node, inclusive: bool = true) ->  Destructable:
    if inclusive && current is Destructable:
        return current as Destructable

    if current == null:
        return null

    var parent: Node = current.get_parent()

    if parent == null:
        return null

    if parent is GridEntity:
        return parent as Destructable

    return find_destructable_parent(parent, false)
