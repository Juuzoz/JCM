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

            # If the path is empty, it's a UI header. Abort the spawn!
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
                        
                    # Find the corresponding magazine to attach visually/functionally
                    var mag_path = ""
                    var expected_mag_key = item_name + " Mag"
                    
                    # Check if standard naming convention works (e.g., "Makarov" -> "Makarov Mag")
                    if JCMDatabase.MAGAZINES.has(expected_mag_key):
                        mag_path = JCMDatabase.MAGAZINES[expected_mag_key]
                    else:
                        # Hardcoded fallbacks for weapons with irregular magazine names in the DB
                        match item_name:
                            "KP-31": mag_path = JCMDatabase.MAGAZINES["KP-31 Drum"]
                            "M4A1": mag_path = JCMDatabase.MAGAZINES["STANAG Mag"]
                            "RK-62", "RK-62M", "RK-95": mag_path = JCMDatabase.MAGAZINES["RK Mag"]
                    
                    # If a valid magazine is found, append its ItemData to the nested array
                    if mag_path != "":
                        var mag_resource = load(mag_path)
                        if mag_resource:
                            newSlotData.nested.append(mag_resource)
                
                # ==========================================
                
                if db_category == JCMDatabase.FURNITURE:
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
            
        print("[JCM] Advanced time by 2 hours. New Time: ", sim.time)

static func rewind_time(mod: Node, travelTime: float):
    var sim = mod.get_node_or_null("/root/Simulation")
    if sim:
        var currentTime = sim.time
        var combinedTime = currentTime - travelTime
        
        if combinedTime < 0.0:
            # Prevent the game from rolling back to Day 0, which might break the save/loader
            if sim.day > 1:
                sim.time = combinedTime + 2400.0
                sim.day -= 1
                sim.weatherTime += travelTime # Reverse the weather progression
            else:
                sim.time = 0.0 # Clamp to midnight on Day 1
        else:
            sim.time = combinedTime
            sim.weatherTime += travelTime
            
        print("[JCM] Rewound time by 2 hours. New Time: ", sim.time)

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

static func trigger_event(mod: Node, func_name: String):
    var map_node = mod.get_node_or_null("/root/Map")
    if not map_node:
        print("[JCM] Error: /root/Map not found.")
        return
        
    var event_sys = _get_event_system(map_node)
    
    # --- JCM CUSTOM EVENT INTERCEPTOR ---
    if func_name == "Police_Drive" or func_name == "Police_Boss":
        var is_boss = (func_name == "Police_Boss")
        _spawn_custom_police(mod, event_sys, is_boss)
        return
    # ------------------------------------
    
    if event_sys and event_sys.has_method(func_name):
        event_sys.call(func_name)
        print("[JCM] Successfully triggered Event: ", func_name)
        
        var loader = mod.get_node_or_null("/root/Loader")
        if loader and loader.has_method("Message"):
            loader.Message("Event Triggered: " + func_name, Color.ORANGE)
    else:
        print("[JCM] Error: Could not find EventSystem or missing method: ", func_name)

static func _spawn_custom_police(mod: Node, event_sys: Node, is_boss: bool):
    var paths = event_sys.get_node_or_null("Paths")
    if not paths or paths.get_child_count() == 0:
        print("[JCM] Error: Could not find Police Paths node.")
        return

    # Grab a random path just like vanilla
    var randomPath = paths.get_child(randi() % paths.get_child_count())
    var inverse = (randi() % 2 == 0) # Maintain the 50/50 direction travel
    
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

    # The vanilla script pauses for 0.1s in _ready() before rolling the random state.
    # We yield for 0.2s to guarantee it finishes its random setup before we overwrite it.
    await mod.get_tree().create_timer(0.2).timeout
    
    # Ensure the car wasn't deleted while we were waiting
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
        
        # Loader.gd reliably sets gameData.shelter = true when loading into a shelter
        if gameData and gameData.get("shelter") == true:
            if loader.has_method("SaveShelter"):
                print("[JCM] Saving current shelter state: ", actual_current_map)
                loader.SaveShelter(actual_current_map)
        # ----------------------------------
        
        if gameData:
            # Safely sync the game's internal tracking variables
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
    
    # If the check is passed (or the cheat is turned off), fire the regular map teleport
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