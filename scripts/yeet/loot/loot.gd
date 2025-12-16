extends Resource
class_name Loot

enum Tag { Stone, Plastic, Glass, Metal, Flammable, Liquid, Sharp, Heavy, Light, Flesh, Thin }

## Reference used in tracking / saving / key-gen for localized names and descriptions
@export var id: String

## If it is less than 1 it cannot be put in inventory
@export var stack_size: int = 1

## In world representation
@export var world_model: PackedScene

## UI representation
@export var ui_texture: Texture2D

## Default cooldown before loot can be thrown again
@export var cooldown: float = 0.4

## Qualifiers that determine how the thing interacts with the world
@export var tags: Array[Tag]

## Human readable name of the thing
var localized_name: String:
    get():
        if localized_name.is_empty():
            localized_name = tr("LOOT_%s_NAME" % id.to_upper())
        return localized_name

## Human readable short fluff what it is
var localized_description: String:
    get():
        if localized_description.is_empty():
            localized_description = tr("LOOT_%s_DESC" % id.to_upper())
        return localized_description
