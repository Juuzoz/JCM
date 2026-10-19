extends Node
class_name JCMActions

static var gameData = preload("res://Resources/GameData.tres")
static var JCMDatabase = preload("res://mods/JCM/JCMDatabase.gd")

static func spawn_item(mod: Node, db_category: Dictionary, index: int, amount: int = 1):
    var interface = mod.get_node_or_null("/root/Map/Core/UI/Interface")
    if interface:
        var options_list = db_category.keys()
        
        if index >= 0 and index < options_list.size():
            var item_name = options_list[index]
            var item_path = db_category[item_name]

            # An empty path is a category header in the dropdown, not an item
            if item_path == "":
                return

            var item_resource = load(item_path)
            
            if item_resource:
                var newSlotData = SlotData.new()
                newSlotData.itemData = item_resource
                newSlotData.amount = amount
                
                # =================
                # SPAWNER MODIFIERS
                # =================
                
                # Spawn Full Magazines
                if db_category == JCMDatabase.MAGAZINES and mod.get("spawn_mags_full_enabled"):
                    if "maxAmount" in item_resource:
                        newSlotData.amount = item_resource.maxAmount
                
                # Spawn Fully Loaded Weapons
                var is_weapon_cat = db_category in [JCMDatabase.PRIMARY_WEAPONS, JCMDatabase.SECONDARY_WEAPONS]
                
                if is_weapon_cat and mod.get("spawn_weaps_with_mag_enabled"):
                    # Put a bullet in the chamber and fill the internal ammo counter
                    newSlotData.chamber = true 
                    if "magazineSize" in item_resource:
                        newSlotData.amount = item_resource.magazineSize
                    elif "maxAmount" in item_resource:
                        newSlotData.amount = item_resource.maxAmount
                        
                    # The weapon's own magazine is the first entry in its compatible list (manual-action weapons have none)
                    var compatible = item_resource.get("compatible")
                    if compatible is Array and not compatible.is_empty():
                        var mag_resource = compatible[0]
                        if mag_resource and mag_resource.get("subtype") == "Magazine":
                            newSlotData.nested.append(mag_resource)
                
                # ==========================================
                
                # Check if it's from the vanilla furniture tab OR if the modded item's internal type is "Furniture"
                var is_furniture = (db_category == JCMDatabase.FURNITURE) or (item_resource.get("type") == "Furniture")
                
                if is_furniture:
                    if interface.get("catalogGrid"):
                        interface.Create(newSlotData, interface.catalogGrid, false)
                        var loader = mod.get_node_or_null("/root/Loader")
                        if loader and loader.has_method("Message"):
                            loader.Message("New Furniture Added [Catalog]", Color.GREEN)
                        else:
                            print("[JCM] Spawned furniture into catalog.")
                    else:
                        print("[JCM] Error: Furniture catalog grid not found!")
                else:
                    interface.Create(newSlotData, interface.inventoryGrid, true)

static func add_time(mod: Node, travelTime: float):
    var sim = mod.get_node_or_null("/root/Simulation")
    if sim:
        var currentTime = sim.time
        var combinedTime = currentTime + travelTime
       
        if combinedTime >= 2400.0:
            sim.time = combinedTime - 2400.0
            sim.day += 1
            sim.weatherTime -= travelTime
            
            var loader = mod.get_node_or_null("/root/Loader")
            if loader and loader.has_method("UpdateProgression"):
                loader.UpdateProgression()
        else:
            sim.time = combinedTime
            sim.weatherTime -= travelTime
            
        print("[JCM] Advanced time by ", travelTime / 100.0, " hours. New Time: ", sim.time)

static func rewind_time(mod: Node, travelTime: float):
    var sim = mod.get_node_or_null("/root/Simulation")
    if sim:
        var currentTime = sim.time
        var combinedTime = currentTime - travelTime
        
        if combinedTime < 0.0:
            # Never roll back past Day 1
            if sim.day > 1:
                sim.time = combinedTime + 2400.0
                sim.day -= 1
                sim.weatherTime += travelTime # Reverse the weather progression
            else:
                sim.time = 0.0 # Clamp to midnight on Day 1
        else:
            sim.time = combinedTime
            sim.weatherTime += travelTime
            
        print("[JCM] Rewound time by ", travelTime / 100.0, " hours. New Time: ", sim.time)

static func change_reputation(mod: Node, amount: float):
    if not gameData:
        return

    gameData.reputation = clampf(gameData.reputation + amount, 0.0, 100.0)
    print("[JCM] Nomad reputation set to: ", gameData.reputation)

    var interface = mod.get_node_or_null("/root/Map/Core/UI/Interface")
    if interface and interface.has_method("Reputation"):
        interface.Reputation()

    var loader = mod.get_node_or_null("/root/Loader")
    if loader and loader.has_method("Message"):
        var color = Color.GREEN if gameData.reputation >= 50.0 else Color.RED
        loader.Message("Nomad Reputation: " + str(int(round(gameData.reputation))), color)

static func set_weather(mod: Node, target_weather: String):
    var sim = mod.get_node_or_null("/root/Simulation")
    if sim:
        sim.weather = target_weather
        sim.weatherTime = 1200.0 
        print("[JCM] Weather forced to: ", target_weather)

static func toggle_season(mod: Node):
    var sim = mod.get_node_or_null("/root/Simulation")
    if sim:
        # Toggle between 1 (Summer) and 2 (Winter)
        if sim.season == 1:
            sim.season = 2
        else:
            sim.season = 1
            
        var season_name = "Winter" if sim.season == 2 else "Summer"
        print("[JCM] Season switched to: ", season_name)
        
        var loader = mod.get_node_or_null("/root/Loader")
        if loader and loader.has_method("Message"):
            loader.Message("Season Changed to " + season_name, Color.CYAN)

static func force_trader_restock(mod: Node):
    var map_node = mod.get_node_or_null("/root/Map")
    if not map_node:
        print("[JCM] Error: /root/Map not found.")
        return
        
    var traders_found = false
    var all_nodes = map_node.find_children("*", "", true, false)
    
    for node in all_nodes:
        if node.has_method("CreateSupply"):
            node.CreateSupply()
            traders_found = true
            
            if "timer" in node and node.timer != null:
                node.timer.start()
    
    if traders_found:
        print("[JCM] All traders in the map have been restocked.")
        var loader = mod.get_node_or_null("/root/Loader")
        if loader and loader.has_method("Message"):
            loader.Message("All Traders Restocked", Color.GREEN)
            
        # --- UI VISUAL REFRESH ---
        var interface = mod.get_node_or_null("/root/Map/Core/UI/Interface")
        if interface and interface.get("trader"):
            if interface.has_method("Resupply"):
                interface.Resupply()
            if interface.has_method("UpdateStats"):
                interface.UpdateStats(true)
    else:
        print("[JCM] No traders found in the current map.")

static func _get_event_system(map_node: Node) -> Node:
    var direct_node = map_node.find_child("Events", true, false)
    if direct_node and direct_node.has_method("FighterJet"): return direct_node
        
    direct_node = map_node.find_child("EventSystem", true, false)
    if direct_node and direct_node.has_method("FighterJet"): return direct_node
        
    var all_nodes = map_node.find_children("*", "", true, false)
    for node in all_nodes:
        if node.has_method("ActivateDynamicEvent") and node.has_method("FighterJet"):
            return node
    return null

# Build 2 EventSystem exposes its vehicle paths through the 'paths' export
static func _get_event_paths(event_sys: Node) -> Node:
    var paths = event_sys.get("paths")
    if not paths:
        paths = event_sys.get_node_or_null("Paths")
    return paths

# Returns the reason an event can't run on the current map, or "" if it can. Vanilla events assume their map nodes
# exist and fail partway through otherwise.
static func _event_unavailable_reason(mod: Node, event_sys: Node, func_name: String) -> String:
    var spawner = event_sys.get("AISpawner")

    match func_name:
        "BTR", "Driver", "Police_Drive", "Police_Boss":
            var paths = _get_event_paths(event_sys)
            if not paths or paths.get_child_count() == 0:
                return "no vehicle paths on this map"
        "CrashSite":
            var crashes = event_sys.get("crashes")
            if not crashes or crashes.get_child_count() == 0:
                return "no crash sites on this map"
        "Bogeyman":
            if not spawner:
                return "AI spawner not ready yet"
            if not ai_enabled(spawner):
                return "AI is disabled on this map"
            var lurks = spawner.get("lurks")
            if not lurks or lurks.is_empty():
                return "no lurk points on this map"
            var boss_pool = spawner.get("BPool")
            if not boss_pool or boss_pool.get_node_or_null("AI_Bogeyman") == null:
                return "Bogeyman is already active or AI is still loading"
        "Gathering":
            if not spawner:
                return "AI spawner not ready yet"
            var gatherings = event_sys.get("gatherings")
            if not gatherings or gatherings.get_child_count() == 0:
                return "no nomad gathering spots on this map"
        "Transmission":
            if mod.get_tree().get_nodes_in_group("Radio").is_empty():
                return "no radios on this map"
    return ""

static func trigger_event(mod: Node, func_name: String):
    var map_node = mod.get_node_or_null("/root/Map")
    if not map_node:
        print("[JCM] Error: /root/Map not found.")
        return

    var event_sys = _get_event_system(map_node)
    var loader = mod.get_node_or_null("/root/Loader")

    if not event_sys:
        print("[JCM] Error: Could not find EventSystem on this map.")
        if loader and loader.has_method("Message"):
            loader.Message("Event Unavailable: no event system on this map", Color.RED)
        return

    var reason = _event_unavailable_reason(mod, event_sys, func_name)
    if reason != "":
        print("[JCM] Event unavailable (", func_name, "): ", reason)
        if loader and loader.has_method("Message"):
            loader.Message("Event Unavailable: " + reason, Color.RED)
        return

    # --- JCM CUSTOM EVENT INTERCEPTOR ---
    if func_name == "Police_Drive" or func_name == "Police_Boss":
        var is_boss = (func_name == "Police_Boss")
        _spawn_custom_police(mod, event_sys, is_boss)
        return
    # ------------------------------------

    if event_sys.has_method(func_name):
        event_sys.call(func_name)
        print("[JCM] Successfully triggered Event: ", func_name)

        if loader and loader.has_method("Message"):
            loader.Message("Event Triggered: " + func_name, Color.ORANGE)
    else:
        print("[JCM] Error: EventSystem is missing method: ", func_name)
        if loader and loader.has_method("Message"):
            loader.Message("Event Unavailable: " + func_name + " does not exist", Color.RED)

static func _spawn_custom_police(mod: Node, event_sys: Node, is_boss: bool):
    var paths = _get_event_paths(event_sys)
    if not paths or paths.get_child_count() == 0:
        print("[JCM] Error: Could not find Police Paths node.")
        return

    # Pick a random path, as vanilla does
    var randomPath = paths.get_child(randi() % paths.get_child_count())
    var inverse = (randi() % 2 == 0) # 50/50 chance of travelling the path in reverse, as vanilla does
    
    var initialWaypoint: Node3D
    if not inverse:
        initialWaypoint = randomPath.get_child(0)
    else:
        initialWaypoint = randomPath.get_child(randomPath.get_child_count() - 1)

    var vehicle_scene = load("res://Assets/Police/Police.tscn")
    if not vehicle_scene:
        print("[JCM] Error: Could not load Police.tscn")
        return

    var instance = vehicle_scene.instantiate()
    event_sys.add_child(instance)

    # Set up the travel path
    instance.selectedPath = randomPath
    instance.inversePath = inverse
    instance.global_transform = initialWaypoint.global_transform

    # The vanilla script waits 0.1s in _ready() before rolling its random state.
    # Waiting 0.2s here makes sure the state set below is applied after that.
    await mod.get_tree().create_timer(0.2).timeout

    # Skip if the vehicle was freed during the wait
    if is_instance_valid(instance):
        if is_boss:
            instance.currentState = 2 # 2 = State.Boss
            if instance.has_method("ActivateLights"):
                instance.ActivateLights()
        else:
            instance.currentState = 1 # 1 = State.Drive
            if instance.has_method("DeactivateLights"):
                instance.DeactivateLights()

    # Success feedback
    var state_str = "Aggro/Boss" if is_boss else "Peaceful"
    print("[JCM] Successfully triggered custom Police event (", state_str, ")")
    
    var loader = mod.get_node_or_null("/root/Loader")
    if loader and loader.has_method("Message"):
        loader.Message("Event Triggered: Police (" + state_str + ")", Color.ORANGE)

static func teleport_to_map(mod: Node, map_name: String):
    # --- TUTORIAL SAFETY CHECK ---
    if gameData and gameData.get("tutorial") == true:
        print("[JCM] Blocked: Cannot teleport out of the Tutorial. It breaks saves!")
        var loader = mod.get_node_or_null("/root/Loader")
        if loader and loader.has_method("Message"):
            loader.Message("Teleport Disabled Here!", Color.RED)
        return
    # -----------------------------

    var ui_manager = mod.get_node_or_null("/root/Map/Core/UI")
    if ui_manager and ui_manager.has_method("ToggleInterface"):
        ui_manager.ToggleInterface()
    else:
        var interface = mod.get_node_or_null("/root/Map/Core/UI/Interface")
        if interface and interface.has_method("Close"): interface.Close()
        if gameData:
            gameData.interface = false
            gameData.isOccupied = false

    var loader = mod.get_node_or_null("/root/Loader")
    
    if loader and loader.has_method("LoadScene"):
        print("[JCM] Initiating Teleport to: ", map_name)
        
        # --- SHELTER SAVE ---
        # Get the exact internal name from the loaded scene file (e.g. "res://Scenes/Cabin.tscn" -> "Cabin")
        var current_scene_file = mod.get_tree().current_scene.scene_file_path
        var actual_current_map = current_scene_file.get_file().get_basename()
        
        # Loader.gd sets gameData.shelter = true when loading into a shelter
        if gameData and gameData.get("shelter") == true:
            if loader.has_method("SaveShelter"):
                print("[JCM] Saving current shelter state: ", actual_current_map)
                loader.SaveShelter(actual_current_map)
        # ----------------------------------
        
        if gameData:
            # Sync the game's internal map tracking variables
            gameData.previousMap = actual_current_map
            gameData.currentMap = map_name
            
        loader.LoadScene(map_name)
        if loader.has_method("SaveCharacter"): loader.SaveCharacter()
        if loader.has_method("SaveWorld"): loader.SaveWorld()
    else:
        print("[JCM] Error: /root/Loader not found.")

static func teleport_to_shelter(mod: Node, map_name: String):
    # --- UNLOCKED SHELTERS ONLY CHECK ---
    if mod.get("teleport_unlocked_shelters_only"):
        var loader = mod.get_node_or_null("/root/Loader")
        if loader and loader.has_method("CheckShelterState"):
            if not loader.CheckShelterState(map_name):
                print("[JCM] Blocked: Player attempted to teleport to a locked shelter.")
                if loader.has_method("Message"):
                    loader.Message("Shelter is Locked!", Color.RED)
                return
    
    # Otherwise, run the regular map teleport
    teleport_to_map(mod, map_name)

static func refresh_open_container(mod: Node):
    var interface = mod.get_node_or_null("/root/Map/Core/UI/Interface")
    
    if not interface or not interface.get("container"): 
        return

    var container = interface.container

    if interface.has_method("ClearContainerGrid"):
        interface.ClearContainerGrid()

    container.loot.clear()
    container.storage.clear()
    container.storaged = false

    if not container.custom.is_empty() and container.force:
        for index in container.table.items.size():
            container.CreateLoot(container.table.items[index])
    else:
        container.GenerateLoot()

    if interface.has_method("FillContainerGrid"):
        interface.FillContainerGrid()

    if interface.has_method("UpdateStats"):
        interface.UpdateStats(true)

    if container.has_method("ContainerAudio"):
        container.ContainerAudio()

    print("[JCM] Container contents re-rolled successfully.")
    
    var loader = mod.get_node_or_null("/root/Loader")
    if loader and loader.has_method("Message"):
        loader.Message("Container Rerolled", Color.ORANGE)
# AI spawning, based on the AI spawner in Ovrrde's Debug Menu (used with permission).
# Spawned AI are new agents rather than ones taken from the map's pools, so they don't use up the map's spawnable AI.
const AI_BOSSES = ["punisher", "bogeyman"]
const CROSSHAIR_RANGE = 150.0

# ai_type is the name of an AI scene variable on AISpawner (bandit, guard, military, nomad, punisher, bogeyman).
# Enemies and nomads wander like natural spawns. Bosses hunt the player, as in the vanilla events.
static func spawn_ai(mod: Node, ai_type: String):
    var loader = mod.get_node_or_null("/root/Loader")
    var spawner = _get_ai_spawner(mod)
    var reason = ""
    if gameData.tutorial or gameData.shelter:
        reason = "AI can't be spawned here"
    elif not ai_enabled(spawner):
        reason = "AI is disabled on this map"
    elif not spawner.get(ai_type) is PackedScene:
        reason = "Unknown AI type: " + ai_type
    if reason != "":
        if loader and loader.has_method("Message"):
            loader.Message("AI Spawn Unavailable: " + reason, Color.RED)
        return

    var position = _crosshair_position(mod)
    if position == Vector3.INF:
        if loader and loader.has_method("Message"):
            loader.Message("Aim at the ground within " + str(int(CROSSHAIR_RANGE)) + " m to spawn AI", Color.RED)
        return

    var is_boss = AI_BOSSES.has(ai_type)
    var is_nomad = ai_type == "nomad"
    var pool = spawner.BPool if is_boss else (spawner.NPool if is_nomad else spawner.EPool)
    var holder = spawner.nomads if is_nomad else spawner.enemies

    # Same setup as AISpawner.CreatePools()
    var agent = spawner.get(ai_type).instantiate()
    pool.add_child(agent, true)
    agent.AISpawner = spawner
    agent.navmesh = spawner.get_world_3d().get_navigation_map()
    agent.global_position = pool.global_position
    agent.Initialize()
    agent.Deactivate()
    await mod.get_tree().process_frame
    if not is_instance_valid(agent) or not is_instance_valid(holder):
        return

    # Same steps as AISpawner.SpawnEnemy() / SpawnMinion() / SpawnBoss()
    agent.reparent(holder)
    agent.global_position = position
    agent.currentPoint = _nearest_waypoint(spawner, position)
    var state = "Attack" if is_boss else "Wander"
    if state == "Attack":
        agent.sensor.force = true
    agent.Activate(state)

    # AI.Death() lowers these for enemies and nomads, but not for bosses
    if is_nomad:
        spawner.activeNomads += 1
    elif not is_boss:
        spawner.activeEnemies += 1

    print("[JCM] Spawned AI: ", ai_type, " (", state, ") at ", position)
    if loader and loader.has_method("Message"):
        loader.Message("Spawned " + ai_type.capitalize(), Color.ORANGE)

# Kills every active nomad, or every active enemy and boss, with the vanilla death, so their bodies can still be looted.
static func kill_all_ai(mod: Node, nomads: bool):
    var loader = mod.get_node_or_null("/root/Loader")
    var spawner = _get_ai_spawner(mod)
    if not ai_enabled(spawner):
        if loader and loader.has_method("Message"):
            loader.Message("No AI on this map", Color.RED)
        return

    var killed = 0
    # Nomad groups are kept with the enemies, so both holders are checked and filtered by faction
    for ai in spawner.enemies.get_children() + spawner.nomads.get_children():
        var variant = ai.get("variant")
        if ai.get("dead") or not ai.get("active") or not variant:
            continue
        if (variant.faction == variant.Faction.Nomad) != nomads:
            continue
        ai.Death(Vector3.UP, 5.0)
        killed += 1

    var killed_text = str(killed) + (" Nomads" if nomads else " Enemies")
    print("[JCM] Killed ", killed_text)
    if loader and loader.has_method("Message"):
        loader.Message("Killed " + killed_text, Color.ORANGE)

# AISpawner.active can't tell whether a map has AI: it is also off after a Nomad Gathering or with Stop AI From
# Spawning. AISpawner.Initialize() only runs on maps with AI, and sets the map's enemy type.
static func ai_enabled(spawner: Node) -> bool:
    return is_instance_valid(spawner) and spawner.get("enemy") != null

static func _get_ai_spawner(mod: Node) -> Node:
    var map_node = mod.get_node_or_null("/root/Map")
    if not map_node:
        return null
    var spawner = map_node.get_node_or_null("AI")
    if spawner and spawner.has_method("SpawnEnemy"):
        return spawner
    var event_sys = _get_event_system(map_node)
    return event_sys.get("AISpawner") if event_sys else null

# Where the player's crosshair hits, moved onto the navigation mesh when it's close by so the AI can walk from there.
# Returns Vector3.INF when nothing is hit within range.
static func _crosshair_position(mod: Node) -> Vector3:
    var camera = mod.get_viewport().get_camera_3d()
    if not camera:
        return Vector3.INF

    var from = camera.global_position
    var query = PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * CROSSHAIR_RANGE)
    var controller = mod.get_node_or_null("/root/Map/Core/Controller")
    if controller:
        query.exclude = [controller.get_rid()]
    var hit = camera.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return Vector3.INF

    var position = hit.position + hit.normal * 0.3
    var nav_position = NavigationServer3D.map_get_closest_point(camera.get_world_3d().navigation_map, position)
    if nav_position != Vector3.ZERO and nav_position.distance_to(position) < 3.0:
        return nav_position + Vector3.UP * 0.2
    return position

static func _nearest_waypoint(spawner: Node, position: Vector3) -> Node3D:
    var nearest: Node3D = null
    var best = INF
    for waypoint in spawner.get("waypoints"):
        if is_instance_valid(waypoint):
            var distance = waypoint.global_position.distance_to(position)
            if distance < best:
                best = distance
                nearest = waypoint
    return nearest
