extends Node

@export_group("Color")
@export var color_enabled: bool
@export var color: Color
@export var metallic: float
@export var roughness: float
# --------------------------------
@export_group("Accessory")
@export var accessory_enabled: bool
@export var accessory: PackedScene
@export var acc_position: Vector3 # Height is 2.0 m, radius is 0.5 m
@export var acc_rotation: Vector3
@export var hide_on_owner: bool # If enabled, hides the accessory on the owner's screen.
# --------------------------------
@export_group("Lobby Music") # If lobby music is enabled, the script MUST be placed on an audio node!
@export var lobby_music_enabled: bool
@export var volume_modifier: float
