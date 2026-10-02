class_name WeaponData
extends Resource
## Static definition of a weapon. One .tres per weapon in data/weapons/.

enum Kind { BALLISTIC, ENERGY, MISSILE }
## Kinetic is strong vs shields, high explosive vs armor, energy is even.
enum DamageType { KINETIC, HIGH_EXPLOSIVE, ENERGY, FRAGMENTATION }

@export var display_name := "Weapon"
@export var kind: Kind = Kind.BALLISTIC
@export var damage_type: DamageType = DamageType.KINETIC

@export_group("Firing")
@export var damage := 20.0
@export var max_range := 600.0
## Seconds between the start of one burst and the next.
@export var refire_delay := 0.5
@export var burst_size := 1
@export var burst_delay := 0.08
@export var flux_per_shot := 10.0
@export var spread_deg := 2.0
## How fast the mount can swivel. Hardpoints should be slow.
@export var turn_rate_deg := 60.0
## -1 means unlimited.
@export var max_ammo := -1

@export_group("Projectile")
@export var projectile_speed := 900.0
@export var projectile_color := Color(1.0, 0.85, 0.4)
@export var projectile_length := 10.0
@export var projectile_width := 2.0
@export var barrel_length := 12.0

@export_group("Missile")
@export var is_missile := false
@export var missile_accel := 600.0
@export var missile_turn_rate_deg := 120.0
