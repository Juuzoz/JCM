extends Node
class_name JCMSaveAnywhere

# Resume Where You Quit: quitting outside a shelter remembers the map and spot, and the main menu's Load button
# brings the player back there instead of to the last shelter.

static var gameData = preload("res://Resources/GameData.tres")
static var MapState = preload("res://mods/JCM/JCMMapState.gd")

const SPOT_FILE = "/save_anywhere.cfg"
const MAP_FILE = "/save_anywhere_map.tres"
const CHARACTER_SAVE = "user://Character.tres"
const NON_MAP_SCENES = ["Menu", "Intro", "Death", "Tutorial", "Template"]

# Returns the player's map and spot, or {} when there is nothing to remember (shelter, tutorial, dead, loading).
static func capture(mod: Node) -> Dictionary:
    if not gameData or gameData.shelter or gameData.tutorial or gameData.isDead or gameData.isTransitioning:
        return {}

    var controller = mod.get_node_or_null("/root/Map/Core/Controller")
    if not controller:
        return {}

    var map_id = _current_map_id(mod)
    if not _is_loadable(mod, map_id):
        return {}

    var pitch = 0.0
    var head = controller.get("head")
    if head:
        pitch = head.rotation.x

    return {
        "map": map_id,
        "position": controller.global_position,
        "yaw": controller.global_rotation.y,
        "pitch": pitch,
    }

# Returns the map's loose items, built-in containers and doors as a JCMMapState, or null if there is no map.
# Must run before the map unloads, like capture().
static func capture_map(mod: Node, map_id: String) -> Resource:
    var map = mod.get_node_or_null("/root/Map")
    if not map:
        return null

    var state = MapState.new()
    state.map = map_id

    for node in map.find_children("*", "", true, false):
        if node is LootContainer and _is_built_in(map, node):
            state.containers.append({
                "path": str(map.get_path_to(node)),
                "loot": node.loot.duplicate(),
                "storage": node.storage.duplicate(),
                "storaged": node.storaged,
                "visible": node.visible,
            })
        elif node is Door and _is_built_in(map, node):
            state.doors.append({"path": str(map.get_path_to(node)), "locked": node.locked, "open": node.isOpen})

    # Same checks as Loader.SaveShelter()
    for item in _loose_items(mod, map):
        if not item.global_position.is_finite() or not item.global_rotation.is_finite() or item.global_position.y < -10.0:
            continue
        var item_save = ItemSave.new()
        item_save.name = item.slotData.itemData.name
        item_save.slotData = item.slotData
        item_save.position = item.global_position
        item_save.rotation = item.global_rotation
        state.items.append(item_save)

    return state

# Call right after Loader.SaveCharacter(), so the spot is tied to that character save.
static func store(file_path: String, spot: Dictionary, map_state: Resource = null):
    var config = ConfigFile.new()
    for key in spot:
        config.set_value("Spot", key, spot[key])
    config.set_value("Spot", "character_saved", FileAccess.get_modified_time(CHARACTER_SAVE))
    config.save(file_path + SPOT_FILE)
    print("[JCM] Resume Where You Quit: Saved spot on ", spot["map"], " at ", spot["position"])

    if map_state:
        ResourceSaver.save(map_state, file_path + MAP_FILE)
        print("[JCM] Resume Where You Quit: Saved ", map_state.items.size(), " items, ", map_state.containers.size(), " containers and ", map_state.doors.size(), " doors")

static func clear(file_path: String):
    for file in [SPOT_FILE, MAP_FILE]:
        if FileAccess.file_exists(file_path + file):
            DirAccess.remove_absolute(file_path + file)

# Returns the saved spot, or {} if there is none or it no longer matches the save.
# Any other character save (transition, death, new game, shelter quit) changes Character.tres, which makes the spot stale.
static func load_spot(mod: Node, file_path: String) -> Dictionary:
    var config = ConfigFile.new()
    if config.load(file_path + SPOT_FILE) != OK:
        return {}

    var saved = config.get_value("Spot", "character_saved", -1)
    if not FileAccess.file_exists(CHARACTER_SAVE) or saved != FileAccess.get_modified_time(CHARACTER_SAVE):
        return {}

    var spot = {}
    for key in config.get_section_keys("Spot"):
        spot[key] = config.get_value("Spot", key)

    if not spot.get("map") is String or not spot.get("position") is Vector3 or not _is_loadable(mod, spot["map"]):
        return {}
    return spot

# Runs when the map starts loading, before its AI spawns. The player position isn't updated while the map loads,
# so setting it to the saved spot makes the spawner keep wandering enemies away from it, as it does around the player.
static func prepare(mod: Node, file_path: String):
    var spot = load_spot(mod, file_path)
    if not spot.is_empty() and _current_map_id(mod) == spot["map"]:
        gameData.playerPosition = spot["position"]

# Moves the player to the saved spot if this map is the one they quit on, and returns true if it did.
# With restore_loot, also puts the map's saved items, container contents and doors back. The save is used up either way.
static func apply(mod: Node, file_path: String, compiler: Node, restore_loot: bool) -> bool:
    var spot = load_spot(mod, file_path)
    if spot.is_empty():
        return false

    var controller = compiler.get("controller") if is_instance_valid(compiler) else null
    if not controller or _current_map_id(mod) != spot["map"]:
        return false

    if restore_loot:
        _restore_map(mod, file_path, spot["map"])
    clear(file_path)

    controller.global_position = spot["position"]
    controller.global_rotation = Vector3(0.0, float(spot.get("yaw", 0.0)), 0.0)
    if "velocity" in controller:
        controller.velocity = Vector3.ZERO
    var head = controller.get("head")
    if head:
        head.rotation.x = float(spot.get("pitch", 0.0))
    gameData.playerPosition = spot["position"]

    var removed = _clear_nearby_ai(mod, spot["position"])
    print("[JCM] Resume Where You Quit: Resumed on ", spot["map"], " at ", spot["position"], ", returned ", removed, " nearby AI to the pool")
    var loader = mod.get_node_or_null("/root/Loader")
    if loader and loader.has_method("Message"):
        loader.Message("Resumed Where You Quit", Color.GREEN)
    return true

# Replaces the freshly generated loot with the saved map contents. Containers and doors that can't be found keep their
# fresh state. If the save can't be loaded at all (e.g. it holds an item from a mod that was removed), the map stays fresh.
static func _restore_map(mod: Node, file_path: String, map_id: String):
    if not FileAccess.file_exists(file_path + MAP_FILE):
        return

    var state = ResourceLoader.load(file_path + MAP_FILE, "", ResourceLoader.CACHE_MODE_IGNORE)
    var map = mod.get_node_or_null("/root/Map")
    if not state or state.get("map") != map_id or not map:
        print("[JCM] Resume Where You Quit: Saved map contents could not be loaded, keeping fresh loot")
        return

    var restored_containers = 0
    for entry in state.containers:
        var container = map.get_node_or_null(NodePath(entry.get("path", "")))
        if not container is LootContainer:
            continue
        _refill(container.loot, entry.get("loot", []))
        _refill(container.storage, entry.get("storage", []))
        container.storaged = entry.get("storaged", false)

        # Hidden stashes are hidden and disabled by LootContainer._ready()
        var shown = entry.get("visible", true)
        if container.visible != shown:
            container.visible = shown
            container.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED
        restored_containers += 1

    var restored_doors = 0
    for entry in state.doors:
        var door = map.get_node_or_null(NodePath(entry.get("path", "")))
        if not door is Door:
            continue
        door.locked = entry.get("locked", door.locked)
        door.isOpen = entry.get("open", door.isOpen)
        # Snap to the end of the open/close animation that Door._physics_process() plays
        door.animationTime = 0.0
        door.position = door.defaultPosition + (door.openOffset if door.isOpen else Vector3.ZERO)
        door.rotation_degrees = door.defaultRotation + (door.openAngle if door.isOpen else Vector3.ZERO)
        restored_doors += 1

    # Same steps as Loader.LoadShelter()
    for item in _loose_items(mod, map):
        item.queue_free()

    var database = mod.get_node_or_null("/root/Database")
    var restored_items = 0
    for item_save in state.items:
        if not item_save or not item_save.slotData or not item_save.slotData.itemData:
            continue
        var scene = database.get(item_save.slotData.itemData.file) if database else null
        if not scene:
            print("[JCM] Resume Where You Quit: File missing: ", item_save.slotData.itemData.file)
            continue

        var pickup = scene.instantiate()
        map.add_child(pickup)
        pickup.slotData.Update(item_save.slotData)
        pickup.global_position = item_save.position
        pickup.global_rotation = item_save.rotation
        pickup.Freeze()
        pickup.UpdateAttachments()
        restored_items += 1

    print("[JCM] Resume Where You Quit: Restored ", restored_items, " items, ", restored_containers, " containers and ", restored_doors, " doors")

static func _refill(target: Array, saved):
    target.clear()
    if saved is Array:
        for slot_data in saved:
            if slot_data is SlotData:
                target.append(slot_data)

# Pickups lying in the map. Weapons and gear carried by AI are pickups too, and are left out.
static func _loose_items(mod: Node, map: Node) -> Array:
    var items = []
    for item in mod.get_tree().get_nodes_in_group("Item"):
        if not item is Pickup or not item.slotData or not item.slotData.itemData or not map.is_ancestor_of(item):
            continue
        var carried = false
        var parent = item.get_parent()
        while parent and parent != map:
            if "AISpawner" in parent and "sensor" in parent:
                carried = true
                break
            parent = parent.get_parent()
        if not carried:
            items.append(item)
    return items

# True for nodes that are part of the map's scene file. Nodes added while playing (AI corpses, airdrops, crash sites)
# belong to scenes instanced at runtime, whose root has no owner, so their paths aren't stable between visits.
static func _is_built_in(map: Node, node: Node) -> bool:
    var root = node
    while root.owner:
        root = root.owner
    return root == map

# Sends active enemies and nomads within the spawner's spawn distance of the spot back to their pool. Guards, hiders and
# groups spawn at fixed points that ignore that distance, so one could otherwise be standing next to the player.
# Returning them, instead of freeing them, keeps the map's total of spawnable AI the same; the spawner later reuses them
# as wandering AI at least that far away. Event bosses are left alone.
static func _clear_nearby_ai(mod: Node, position: Vector3) -> int:
    var tree = mod.get_tree()
    var checked = {}
    var removed = 0

    for id in tree.get_nodes_in_group("AI") + tree.get_nodes_in_group("Nomad"):
        var ai = id.owner
        if not is_instance_valid(ai) or checked.has(ai):
            continue
        checked[ai] = true

        var spawner = ai.get("AISpawner")
        var variant = ai.get("variant")
        if not is_instance_valid(spawner) or not variant or not ai.get("active") or ai.get("dead"):
            continue
        if variant.faction == variant.Faction.Boss:
            continue

        var radius = float(spawner.get("spawnDistance")) if spawner.get("spawnDistance") else 100.0
        if ai.global_position.distance_to(position) > radius:
            continue

        var is_nomad = variant.faction == variant.Faction.Nomad
        var pool = spawner.get("NPool") if is_nomad else spawner.get("EPool")
        if not is_instance_valid(pool):
            continue

        # Same steps as AISpawner.CreatePools(), plus the active count that AI.Death() lowers
        ai.Deactivate()
        ai.reparent(pool)
        ai.global_position = pool.global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
        if is_nomad:
            spawner.activeNomads -= 1
        else:
            spawner.activeEnemies -= 1
        spawner.groupMembers.erase(ai)
        removed += 1

    return removed

# Same map id the teleport uses (e.g. "res://Scenes/Village.scn" -> "Village")
static func _current_map_id(mod: Node) -> String:
    var map = mod.get_node_or_null("/root/Map")
    if not map:
        return ""
    return map.scene_file_path.get_file().get_basename()

# True if Loader.LoadScene() knows the map: a vanilla scene constant, or a scene registered through the mod loader.
static func _is_loadable(mod: Node, map_id: String) -> bool:
    if map_id == "" or NON_MAP_SCENES.has(map_id):
        return false

    var loader = mod.get_node_or_null("/root/Loader")
    if loader and loader.get_script() and loader.get_script().get_script_constant_map().get(map_id) is String:
        return true

    return mod.JCMDynamic._registry_keys(mod, "scene_paths").has(map_id)
