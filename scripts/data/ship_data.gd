class_name ShipData
extends Resource
## Static definition of a hull: stats, placeholder look and weapon mounts.
## One .tres per hull in data/ships/. Ships face +X.

@export var display_name := "Ship"
@export var hull_class := "Frigate"

@export_group("Durability")
@export var max_hull := 1000.0
@export var max_armor := 100.0

@export_group("Flux")
@export var flux_capacity := 2000.0
## Flux removed per second. Hard flux only dissipates with shields down.
@export var flux_dissipation := 150.0

@export_group("Shield")
@export var shield_arc_deg := 180.0
## Flux generated per point of damage absorbed. Lower is better.
@export var shield_efficiency := 1.0
## Soft flux per second while the shield is up.
@export var shield_upkeep := 20.0

@export_group("Mobility")
@export var max_speed := 150.0
@export var acceleration := 200.0
@export var turn_rate_deg := 90.0
@export var turn_acceleration_deg := 180.0

@export_group("Look")
@export var radius := 30.0
@export var hull_color := Color(0.5, 0.6, 0.7)
@export var accent_color := Color(0.8, 0.9, 1.0)
@export var outline := PackedVector2Array()
@export var engine_points := PackedVector2Array()

@export_group("Weapons")
@export var mounts: Array[WeaponMount] = []
