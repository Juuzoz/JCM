extends Resource

# A field map's contents, saved by Resume Where You Quit when the player quits and restored when they resume.
# Containers and doors are identified by their node path from /root/Map.

@export var map: String
@export var items: Array[ItemSave] = []
@export var containers: Array[Dictionary] = [] # {path, loot, storage, storaged, visible}
@export var doors: Array[Dictionary] = [] # {path, locked, open}
