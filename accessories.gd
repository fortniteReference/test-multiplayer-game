extends Node

@export_group("Color")
@export var color_enabled: bool
@export var color: Color
@export var metallic: float
@export var roughness: float
# --------------------------------
@export_group("Accessory")
@export var accessory_enabled: bool
@export var acc_position: Vector3
# --------------------------------
@export_group("Lobby Music") # If lobby music is enabled, the script MUST be placed on an audio node!
@export var lobby_music_enabled: bool
@export var volume_modifier: float
