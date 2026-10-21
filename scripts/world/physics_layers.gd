class_name PhysicsLayers
extends RefCounted
## Collision layer bits. Trees, rocks, water and walls use WORLD (Godot's default layer 1).
## The ranger and critters only bump into the world, not into each other.

const WORLD: int = 1
const RANGER: int = 2
const CRITTERS: int = 4
