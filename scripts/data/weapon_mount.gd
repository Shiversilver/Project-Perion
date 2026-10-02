class_name WeaponMount
extends Resource
## A weapon slot on a hull: where it sits, which way it faces, how far it can
## swivel, what is fitted and which weapon group it belongs to.

@export var offset := Vector2.ZERO
@export var facing_deg := 0.0
## Total swivel arc. ~10 = hardpoint, 180+ = turret.
@export var arc_deg := 180.0
@export var weapon: WeaponData
@export_range(1, 5) var group := 1
