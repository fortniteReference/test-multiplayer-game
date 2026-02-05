extends Node3D
# Essentials
@export var image: String # Image displayed on the hotbar. res:// path required
@export var hitscan: bool # whether the weapon is hitscan (uses raycast), or not.
@export var shotgun: bool # enables pellets and special reticle
# Aiming in
@export var fov: int = 75 # FOV for aiming in. Less = more zoomed in, and vice versa
@export var custom_reticle: bool # disables the reticle when aiming in if enabled
# Weapon Configuring
@export var ammo: int # ammo given before having to reload
@export var damage: int # damage dealt to the player
@export var headshot_multiplier: float = 1.0 # Multiplier when the player hits a headshot
@export var cooldown: float # cooldown between shots
@export var spread: float # Spread/recoil of the weapon's bullets
@export var spread_reduction: int # Spread reduction when aiming in (in percent)
@export var weapon_range: int # Range (in m) of the weapon
@export var bullet_time: float # NOTICE: this only applies if the weapon is projectile!
@export var pellets: int # Determines amount of pellets. Only works with shotgun enabled.
@export var reload_time: float # time (secs) for it to reload
@export var shotgun_reload: bool # Determines if the weapon reloads one-at-a-time
# Falloff damage Configuring
@export var falloff_enabled: bool = true # deteremines if damage falloff is allowed.
@export var falloff_start: int # distance where damage will start to fall off
@export var falloff_damage: int = 1 # the amount of damage that falls off per m
@export var falloff_minimum: int = 1 # the least damage it can do after the max falloff distance is reached
@export var target_multiplier: float = 1.0 # multiplier of the falloff start distance when aiming in
# Burst Configuring
@export var burst_enabled: bool # determines whether burst fire is enabled
@export var burst_amount: int # amount of shots per burst. only works if burst_enabled is true
@export var burst_cooldown: float # cooldown between bullets. only works if burst_enabled is true
