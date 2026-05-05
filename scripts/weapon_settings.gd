extends Node3D
# Essentials
@export_group("Essentials")
@export var image: String # Image displayed on the hotbar. res:// path required
@export var item_name: String
@export var hitscan: bool # whether the weapon is hitscan (uses raycast), or not.
@export var shotgun: bool # enables pellets and special reticle
# Aiming in
@export_group("Aiming In")
@export var fov: int = 75 # FOV for aiming in. Less = more zoomed in, and vice versa
@export var custom_reticle: bool # disables the reticle when aiming in if enabled
# Weapon Configuring
@export_group("Weapon Configuring")
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
@export_group("Falloff Damage")
@export var falloff_enabled: bool = true # deteremines if damage falloff is allowed.
@export var falloff_start: int # distance where damage will start to fall off
@export var falloff_damage: float = 1 # the amount of damage that falls off per meter
@export var falloff_minimum: int = 1 # the least damage it can do after the max falloff distance is reached
@export var target_multiplier: float = 1.0 # multiplier of the falloff start distance when aiming in
# Burst Configuring
@export_group("Burst Settings")
@export var burst_enabled: bool # determines whether burst fire is enabled
@export var burst_amount: int # amount of shots per burst. only works if burst_enabled is true
@export var burst_cooldown: float # cooldown between bullets. only works if burst_enabled is true
# Utility Settings
# NOTICE: For a utility item to work, there must be a child node called "utility_function" 
# with a script with function "run_function()," and throwables must have an area3d node
# called "area"
@export_group("Utility Settings")
@export var utility_enabled: bool
@export var utility_scene: PackedScene
@export var throwable: bool
@export var infinite: bool
@export var throw_force: float
@export var activate_on_impact: bool
@export var activate_delay: float
@export var delete_after_activation: bool
@export var delete_delay: float
# Animation of weapon
@export_group("Animation Settings")
@export var play_animation: bool = true
@export var rotate_degrees: int = 5
@export var reset_time: float = 0.3
@export var rotate_axis: String = "x"
@export var flash_muzzle: bool
@export var muzzle_size: float = 0.05
@export var muzzle_image: String = "res://addons/kenney_particle_pack/muzzle_02.png"
