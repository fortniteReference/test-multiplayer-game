extends Node3D
# Essentials
@export var image: String # Image displayed on the hotbar. res:// path required
@export var hitscan: bool # whether the weapon is hitscan (uses raycast), or not.
@export var shotgun: bool # enables pellets and special reticle
# Weapon Configuring
@export var ammo: int
@export var damage: int
@export var headshot_multiplier: float = 1.0
@export var cooldown: float
@export var spread: float
@export var weapon_range: int
@export var pellets: int
@export var reload_time: float
@export var shotgun_reload: bool
