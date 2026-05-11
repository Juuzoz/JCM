extends Node

var McmHelpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")
var gameData = preload("res://Resources/GameData.tres")
var JCMDatabase = preload("res://mods/JCM/JCMDatabase.gd")
var JCMConfig = preload("res://mods/JCM/JCMConfig.gd")
var JCMActions = preload("res://mods/JCM/JCMActions.gd")

const FILE_PATH = "user://MCM/juuzoz-jcm"
const MOD_ID = "juuzoz-jcm"

# Cheat toggles
var god_mode_enabled = false
var enemies_ignore_enabled = false 
var max_needs_enabled = false 
var infinite_stamina_enabled = false
var no_weight_limit_enabled = false
var fast_movement_enabled = false
var big_jumps_enabled = false
var keep_gear_enabled = false
var keep_gear_on_quit_enabled = false
var disable_permadeath_enabled = false
var infinite_ammo_enabled = false
var infinite_weapon_durability_enabled = false
var infinite_gear_durability_enabled = false
var never_jam_enabled = false
var immortal_cat_enabled = false
var spawn_mags_full_enabled = false
var spawn_weaps_with_mag_enabled = false

# Internal state trackers
var _lib = null
var _ai_refresh_timer = 0.0
var was_dead = false
var noclip_enabled = false
var _was_noclip = false 

# Movement State Trackers
var _was_fast_movement = false
var _was_big_jumps = false

# MCM defaults
var key_noclip = KEY_CAPSLOCK
var key_refresh_container = KEY_KP_1 
var key_trader_restock = KEY_KP_2
var custom_walk_speed = 5.0
var custom_sprint_speed = 10.0
var custom_jump_velocity = 14.0
var keep_equipped_only = false
var keep_equipped_only_on_quit = false
var teleport_unlocked_shelters_only = false

# UI dropdown tracking
var weather_options = ["Neutral", "Aurora", "Storm", "Rain", "Overcast", "Wind", "Fog", "Custom"]
var event_options = {"Airdrop (CASA)": "Airdrop", "Fighter Jet": "FighterJet", "Helicopter": "Helicopter", "Crash Site": "CrashSite", "BTR": "BTR", "Police (Peaceful)": "Police_Drive", "Police (Aggro)": "Police_Boss"}
var map_options = {"Village": "Village", "Highway": "Highway", "School": "School", "Outpost": "Outpost", "Apartments": "Apartments", "Terminal": "Terminal", "Template (Dev room)": "Template"}
var shelter_options = {"Cabin": "Cabin", "Attic": "Attic", "Classroom": "Classroom", "Tent": "Tent", "Bunker": "Bunker"}

var sel_weather = 0
var sel_event = 0
var sel_map = 0
var sel_shelter = 0
var sel_primary = 0
var sel_secondary = 0
var sel_mag = 0
var sel_ammo = 0
var sel_med = 0
var sel_gear = 0
var sel_attach = 0
var sel_food = 0
var sel_keys = 0
var sel_furn = 0
var sel_misc = 0
var sel_modded = 0

var modded_items = {} # Holds items discovered from other mods

# UI injection state
var jcm_ui_injected = false
var jcm_ui_builder = preload("res://mods/JCM/JCM_UI.gd")
var jcm_ui_instance = null
var jcm_button = null


# Sets up the Mod Configuration Menu (MCM) and registers our hook callbacks with MML.
func _ready():
    load_jcm_config()
    
    if McmHelpers:
        var _config = ConfigFile.new()
        _config.set_value("Keycode", "noclipKey", {"name" = "Toggle Noclip", "tooltip" = "Press to fly.", "default" = KEY_CAPSLOCK, "value" = key_noclip})
        _config.set_value("Keycode", "refreshContainerKey", {"name" = "Refresh Open Container", "tooltip" = "Press while looting to re-roll the container's contents.", "default" = KEY_KP_1, "value" = key_refresh_container})
        _config.set_value("Keycode", "refreshTraderKey", {"name" = "Force Trader Restock", "tooltip" = "Press to instantly restock all traders on the current map.", "default" = KEY_KP_2, "value" = key_trader_restock})
        _config.set_value("Float", "walkSpeed", {"name" = "Fast Walk Speed", "default" = 5.0, "value" = custom_walk_speed, "minRange" = 1.0, "maxRange" = 20.0})
        _config.set_value("Float", "sprintSpeed", {"name" = "Fast Sprint Speed", "default" = 10.0, "value" = custom_sprint_speed, "minRange" = 2.0, "maxRange" = 30.0})
        _config.set_value("Float", "jumpVelocity", {"name" = "Big Jump Height", "default" = 14.0, "value" = custom_jump_velocity, "minRange" = 5.0, "maxRange" = 50.0})
        _config.set_value("Bool", "keepEquippedOnly", {"name" = "Only keep equipped items on death while using 'Keep Gear on Death' cheat", "tooltip" = "If 'Keep Gear' is enabled, you will still lose items in your inventory, but keep equipped weapons and armor.", "default" = false, "value" = keep_equipped_only})
        _config.set_value("Bool", "keepEquippedOnlyOnQuit", {"name" = "Only keep equipped items on quit while using 'Keep Gear on Quit' cheat", "tooltip" = "If 'Keep Gear on Quit' is enabled, you will still lose items in your inventory, but keep equipped weapons and armor.", "default" = false, "value" = keep_equipped_only_on_quit})
        _config.set_value("Bool", "unlockedSheltersOnly", {"name" = "Only able to Teleport to discovered/unlocked shelters", "tooltip" = "Prevents teleporting to shelters you haven't found or unlocked yet.", "default" = false, "value" = teleport_unlocked_shelters_only})

        if not FileAccess.file_exists(FILE_PATH + "/config.ini"):
            DirAccess.make_dir_recursive_absolute(FILE_PATH)
            _config.save(FILE_PATH + "/config.ini")
        else:
            McmHelpers.CheckConfigurationHasUpdated(MOD_ID, _config, FILE_PATH + "/config.ini")
            _config.load(FILE_PATH + "/config.ini")
            
        McmHelpers.RegisterConfiguration(MOD_ID, "Juuzoz Cheat Menu", FILE_PATH, "In-game cheats and item spawner.", { "config.ini": Callable(self, "UpdateConfigProperties") })
        UpdateConfigProperties(_config)
        
    if Engine.has_meta("RTVModLib"):
        var lib = Engine.get_meta("RTVModLib")
        if lib.get("_is_ready"):
            _on_lib_ready()
        else:
            lib.frameworks_ready.connect(_on_lib_ready)

# Syncs internal variables whenever the user updates their MCM settings.
func UpdateConfigProperties(config: ConfigFile):
    key_noclip = config.get_value("Keycode", "noclipKey")["value"]
    if config.has_section_key("Keycode", "refreshContainerKey"):
        key_refresh_container = config.get_value("Keycode", "refreshContainerKey")["value"]
    if config.has_section_key("Keycode", "refreshTraderKey"):
        key_trader_restock = config.get_value("Keycode", "refreshTraderKey")["value"]
    custom_walk_speed = config.get_value("Float", "walkSpeed")["value"]
    custom_sprint_speed = config.get_value("Float", "sprintSpeed")["value"]
    custom_jump_velocity = config.get_value("Float", "jumpVelocity")["value"]
    if config.has_section_key("Bool", "keepEquippedOnly"):
        keep_equipped_only = config.get_value("Bool", "keepEquippedOnly")["value"]
    if config.has_section_key("Bool", "keepEquippedOnlyOnQuit"):
        keep_equipped_only_on_quit = config.get_value("Bool", "keepEquippedOnlyOnQuit")["value"]
    if config.has_section_key("Bool", "unlockedSheltersOnly"):
        teleport_unlocked_shelters_only = config.get_value("Bool", "unlockedSheltersOnly")["value"]

# Registers our hooks once MML finishes initializing.
func _on_lib_ready():
    _lib = Engine.get_meta("RTVModLib")
    _lib.hook("interface-open-post", _on_interface_open)
    _lib.hook("settings-_ready-post", _on_settings_ready)
    _lib.hook("settings-_on_exit_menu_pressed-pre", _on_custom_exit_pressed)
    _lib.hook("settings-_on_exit_quit_pressed-pre", _on_custom_exit_pressed)
    _lib.hook("controller-_physics_process-post", _on_controller_process)
    print("[JCM] Cheat Menu hooks registered successfully.")


# Safely pulls any new items registered by other mods out of MML's internal data structures.
func populate_modded_items():
    modded_items.clear()
    if not _lib: return
    
    for prop in _lib.get_property_list():
        var val = _lib.get(prop.name)
        if typeof(val) == TYPE_DICTIONARY:
            for registry_name in ["items", "loot"]:
                if val.has(registry_name) and typeof(val[registry_name]) == TYPE_DICTIONARY:
                    var registry_store = val[registry_name]
                    for key in registry_store:
                        _try_add_modded_item(registry_store[key])

# Helper for the scanner. Validates the item data before adding it to the modded dropdown.
func _try_add_modded_item(res):
    var item_data = null
    
    if typeof(res) == TYPE_DICTIONARY and res.has("item"):
        item_data = res["item"]
    elif res is Resource:
        item_data = res
        
    if item_data and "name" in item_data and "file" in item_data and "type" in item_data:
        var path = item_data.resource_path
        if path and not _is_vanilla_item(path):
            var display_name = item_data.name
            if modded_items.values().has(path): return 
            
            if modded_items.has(display_name):
                display_name += " (" + path.get_file() + ")"
                
            modded_items[display_name] = path

# Helper to ensure we don't accidentally list vanilla items in the modded category.
func _is_vanilla_item(path: String) -> bool:
    if not JCMDatabase: return false
    var all_dicts = [JCMDatabase.PRIMARY_WEAPONS, JCMDatabase.SECONDARY_WEAPONS, JCMDatabase.MAGAZINES, JCMDatabase.AMMO, JCMDatabase.MEDICAL, JCMDatabase.GEAR, JCMDatabase.ATTACHMENTS, JCMDatabase.FOOD, JCMDatabase.KEYS, JCMDatabase.FURNITURE, JCMDatabase.MISC]
    for d in all_dicts:
        if path in d.values():
            return true
    return false


# Fires whenever the inventory is opened. Re-injects the cheat menu UI if needed.
func _on_interface_open():
    var interface_instance = _lib._caller
    
    if modded_items.is_empty():
        populate_modded_items()
        
    if not is_instance_valid(jcm_button):
        jcm_ui_instance = jcm_ui_builder.new()
        jcm_ui_injected = jcm_ui_instance.inject(self, interface_instance)
        
    if is_instance_valid(jcm_button) and jcm_button.disabled:
        jcm_button.disabled = false

# Connects to the warnings on the pause screen so we can change the text.
func _on_settings_ready():
    var settings_instance = _lib._caller
    var warning_node = settings_instance.get_node_or_null("Warning")
    if warning_node and not warning_node.visibility_changed.is_connected(_on_warning_visibility_changed):
        warning_node.visibility_changed.connect(func(): _on_warning_visibility_changed(warning_node))

# Dynamically updates the quit warning to let players know their gear is safe.
func _on_warning_visibility_changed(warning_node):
    if not warning_node.visible: return
    var labels = warning_node.find_children("*", "Label", true, false)
    for lbl in labels:
        if keep_gear_on_quit_enabled:
            lbl.text = "JCM Active: Your gear will be safely auto-saved when you quit."
            lbl.modulate = Color.GREEN
        else:
            lbl.text = "WARNING: Unsaved progress and gear will be lost."
            lbl.modulate = Color.WHITE

# Intercepts the quit button. Saves character data right before the vanilla code deletes it.
func _on_custom_exit_pressed():
    if not keep_gear_on_quit_enabled: return
    if gameData and gameData.get("tutorial") == true: return 
        
    var loader = get_node_or_null("/root/Loader")
    if not loader: return
    
    var settings_instance = _lib._caller
    if keep_equipped_only_on_quit:
        var interface = settings_instance.get_node_or_null("../Interface")
        if interface and interface.get("inventoryGrid"):
            for item in interface.inventoryGrid.get_children():
                interface.inventoryGrid.remove_child(item)
                item.queue_free()
                
    await get_tree().create_timer(0.1).timeout
    if loader.has_method("SaveCharacter"): 
        loader.SaveCharacter()

# Main cheat loop. Runs every physics frame alongside the player's controller.
func _on_controller_process(delta):
    if not gameData: return
    
    var controller_instance = _lib._caller
    var interface = controller_instance.get_node_or_null("/root/Map/Core/UI/Interface")
    
    _handle_invisibility(controller_instance, delta)
    _handle_noclip(controller_instance, delta)
    _handle_weapons_and_ammo(interface)
    _handle_vitals_and_permadeath(controller_instance)
    _handle_inventory_limits(interface)
    _handle_movement(controller_instance)
    _handle_needs_and_god_mode(controller_instance)


# Listens for direct key presses for cheats like noclip and container rerolling.
func _input(event):
    if event is InputEventKey and event.pressed:
        if event.physical_keycode == key_noclip:
            noclip_enabled = !noclip_enabled
            save_jcm_config()
            if jcm_ui_injected and jcm_ui_instance and jcm_ui_instance.has_method("update_toggle"):
                jcm_ui_instance.update_toggle("noclip_enabled", noclip_enabled)
        if event.physical_keycode == key_refresh_container:
            if JCMActions: JCMActions.refresh_open_container(self)
        if event.physical_keycode == key_trader_restock:
            if JCMActions: JCMActions.force_trader_restock(self)


# Detaches the player from the AI's sensor group, rendering them invisible.
func _handle_invisibility(controller, delta):
    if controller:
        if enemies_ignore_enabled:
            if controller.is_in_group("Player"): controller.remove_from_group("Player")
        else:
            if not controller.is_in_group("Player"): controller.add_to_group("Player")

    _ai_refresh_timer += delta
    if _ai_refresh_timer > 0.5:
        _ai_refresh_timer = 0.0
        var ai_spawner = get_node_or_null("/root/Map/AI")
        if ai_spawner:
            var all_ai = ai_spawner.find_children("*", "CharacterBody3D", true, false)
            for ai in all_ai:
                if "sensorActive" in ai:
                    if enemies_ignore_enabled:
                        ai.sensorActive = false
                        ai.playerVisible = false
                        var state = ai.get("currentState")
                        if state != null and typeof(state) == TYPE_INT and state in [5, 6, 7, 8, 9, 10, 11, 12]:
                            if ai.has_method("ChangeState"):
                                ai.ChangeState("Wander")
                        if "lastKnownLocation" in ai: ai.lastKnownLocation = ai.global_position
                    elif not ai.sensorActive:
                        ai.sensorActive = true

# Disables collision and handles keyboard input for flight. 
func _handle_noclip(controller, delta):
    if controller:
        if noclip_enabled:
            gameData.isFlying = true
            _was_noclip = true
            for child in controller.get_children():
                if child is CollisionShape3D and not child.disabled:
                    child.disabled = true
            if "velocity" in controller: controller.velocity = Vector3.ZERO
            
            var cam = get_viewport().get_camera_3d()
            if cam:
                var fly_speed = 15.0 if Input.is_key_pressed(KEY_SHIFT) else 5.0
                var dir = Vector3.ZERO
                if Input.is_key_pressed(KEY_W): dir -= cam.global_transform.basis.z
                if Input.is_key_pressed(KEY_S): dir += cam.global_transform.basis.z
                if Input.is_key_pressed(KEY_A): dir -= cam.global_transform.basis.x
                if Input.is_key_pressed(KEY_D): dir += cam.global_transform.basis.x
                if dir != Vector3.ZERO:
                    controller.global_position += dir.normalized() * fly_speed * delta
        else:
            gameData.isFlying = false
            if _was_noclip:
                var is_crouching = false
                if gameData and gameData.get("isCrouching") == true:
                    is_crouching = true
                var shapes = []
                for child in controller.get_children():
                    if child is CollisionShape3D:
                        shapes.append(child)
                if shapes.size() >= 2:
                    shapes[0].disabled = is_crouching
                    shapes[1].disabled = not is_crouching
                elif shapes.size() == 1:
                    shapes[0].disabled = false
                _was_noclip = false

# Overrides ammo consumption and durability mechanics.
func _handle_weapons_and_ammo(interface):
    var rigManager = get_node_or_null("/root/Map/Core/Camera/Manager")
    if rigManager:
        var active_weapon = null
        if gameData.primary and rigManager.get("primarySlot") and rigManager.primarySlot.get_child_count() > 0:
            active_weapon = rigManager.primarySlot.get_child(0)
        elif gameData.secondary and rigManager.get("secondarySlot") and rigManager.secondarySlot.get_child_count() > 0:
            active_weapon = rigManager.secondarySlot.get_child(0)
            
        if active_weapon and active_weapon.get("slotData"):
            if infinite_ammo_enabled:
                var weapon_data = active_weapon.slotData.itemData
                if weapon_data and weapon_data.get("magazineSize"):
                    active_weapon.slotData.amount = weapon_data.magazineSize
            if infinite_weapon_durability_enabled and "condition" in active_weapon.slotData:
                if active_weapon.slotData.condition < 100.0: active_weapon.slotData.condition = 100.0
            if never_jam_enabled and active_weapon.slotData.get("state") == "Jammed":
                active_weapon.slotData.state = ""
                if interface and interface.has_method("UpdateUIDetails"): interface.UpdateUIDetails()

# Revives the player and restores their health stats if they die with the cheat on.
func _handle_vitals_and_permadeath(controller):
    if disable_permadeath_enabled and gameData.permadeath:
        gameData.permadeath = false
    
    if gameData.isDead:
        if not was_dead:
            was_dead = true
            if keep_gear_enabled:
                if gameData and gameData.get("tutorial") == true: return 
                gameData.health = 100.0
                gameData.energy = 100.0
                gameData.hydration = 100.0
                gameData.mental = 100.0
                gameData.temperature = 100.0
                gameData.bleeding = false
                gameData.fracture = false
                gameData.rupture = false
                gameData.headshot = false

                if keep_equipped_only:
                    var interface = get_node_or_null("/root/Map/Core/UI/Interface")
                    if interface:
                        var inventory = interface.get("inventoryGrid")
                        if inventory:
                            for item in inventory.get_children():
                                inventory.remove_child(item)
                                item.queue_free()

                var loader = get_node_or_null("/root/Loader")
                if loader: loader.SaveCharacter()
    else:
        if was_dead: was_dead = false

# Overrides weight constraints and manages overall gear durability.
func _handle_inventory_limits(interface):
    if interface:
        interface.baseCarryWeight = 9999.0 if no_weight_limit_enabled else 10.0
        if infinite_gear_durability_enabled or infinite_weapon_durability_enabled:
            var equipment = interface.get("equipment")
            if equipment:
                for slot in equipment.get_children():
                    if slot.get_child_count() > 0: _repair_item_if_applicable(slot.get_child(0))
            var inventory = interface.get("inventoryGrid")
            if inventory:
                for item in inventory.get_children(): _repair_item_if_applicable(item)

# Applies custom speeds when ON, and reverts to vanilla when turned OFF.
func _handle_movement(controller):
    if not controller: return
    
    # --- Walk & Sprint ---
    if fast_movement_enabled:
        controller.walkSpeed = custom_walk_speed
        controller.sprintSpeed = custom_sprint_speed
        _was_fast_movement = true
    elif _was_fast_movement:
        # This only runs for a single frame right after you turn the cheat off.
        controller.walkSpeed = 2.5
        controller.sprintSpeed = 5.0
        _was_fast_movement = false
        
    # --- Jumps ---
    if big_jumps_enabled:
        controller.jumpVelocity = custom_jump_velocity
        _was_big_jumps = true
    elif _was_big_jumps:
        # This only runs for a single frame right after you turn the cheat off.
        controller.jumpVelocity = 7.0
        _was_big_jumps = false

# Freezes health and core survival needs. 
func _handle_needs_and_god_mode(controller):
    if god_mode_enabled:
        gameData.health = 100.0
        gameData.bleeding = false
        gameData.fracture = false
        gameData.rupture = false
        gameData.burn = false
        gameData.headshot = false
        gameData.poisoning = false
        if controller: controller.fallThreshold = 9999.0
    else:
        if controller and controller.get("fallThreshold") == 9999.0: controller.fallThreshold = 5.0
        
    if max_needs_enabled:
        gameData.energy = 100.0
        gameData.hydration = 100.0
        gameData.mental = 100.0
        gameData.temperature = 100.0
        gameData.oxygen = 100.0
        gameData.frostbite = false
        gameData.insanity = false
        gameData.starvation = false
        gameData.dehydration = false
        
    if infinite_stamina_enabled:
        gameData.bodyStamina = 100.0
        gameData.armStamina = 100.0

    if immortal_cat_enabled:
        gameData.cat = 100.0
        if gameData.catDead: gameData.catDead = false

# Instantly sets an item's condition to 100% and refreshes its UI if necessary.
func _repair_item_if_applicable(item):
    if item.get("slotData") and "condition" in item.slotData and item.slotData.get("itemData"):
        var is_weapon = (item.slotData.itemData.get("type") == "Weapon")
        var should_repair = (is_weapon and infinite_weapon_durability_enabled) or (not is_weapon and infinite_gear_durability_enabled)
        if should_repair and item.slotData.condition < 100.0:
            item.slotData.condition = 100.0
            if item.has_method("UpdateDetails"): item.UpdateDetails()


# ==========================================
# ACTION WRAPPERS
# Pass-through functions for buttons to execute logic stored in JCMActions.gd
# ==========================================
func spawn_item(db_category: Dictionary, index: int, amount: int = 1):
    if JCMActions: JCMActions.spawn_item(self, db_category, index, amount)
func add_time(travelTime: float):
    if JCMActions: JCMActions.add_time(self, travelTime)
func set_weather(target_weather: String):
    if JCMActions: JCMActions.set_weather(self, target_weather)
func rewind_time(travelTime: float):
    if JCMActions: JCMActions.rewind_time(self, travelTime)
func toggle_season():
    if JCMActions: JCMActions.toggle_season(self)
func force_trader_restock():
    if JCMActions: JCMActions.force_trader_restock(self)
func trigger_event(func_name: String):
    if JCMActions: JCMActions.trigger_event(self, func_name)
func teleport_to_map(map_name: String):
    if JCMActions: JCMActions.teleport_to_map(self, map_name)
func teleport_to_shelter(map_name: String):
    if JCMActions: JCMActions.teleport_to_shelter(self, map_name)

# ==========================================
# CONFIG WRAPPERS
# ==========================================
func load_jcm_config():
    if JCMConfig: JCMConfig.load_config(self, FILE_PATH)
func save_jcm_config():
    if JCMConfig: JCMConfig.save_config(self, FILE_PATH)