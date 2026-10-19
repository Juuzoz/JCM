extends Node

var McmHelpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")
var gameData = preload("res://Resources/GameData.tres")
var JCMDatabase = preload("res://mods/JCM/JCMDatabase.gd")
var JCMConfig = preload("res://mods/JCM/JCMConfig.gd")
var JCMActions = preload("res://mods/JCM/JCMActions.gd")
var JCMDynamic = preload("res://mods/JCM/JCMDynamicLists.gd")
var JCMSaveAnywhere = preload("res://mods/JCM/JCMSaveAnywhere.gd")

const FILE_PATH = "user://MCM/juuzoz-jcm"
const MOD_ID = "juuzoz-jcm"
const MCM_CATEGORIES = ["Hotkeys", "Movement", "Keep Gear", "Resume Where You Quit", "World"] # In menu order
var _mcm_menu_pos = 0

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
var save_anywhere_enabled = false
var disable_permadeath_enabled = false
var infinite_ammo_enabled = false
var infinite_weapon_durability_enabled = false
var infinite_gear_durability_enabled = false
var never_jam_enabled = false
var immortal_cat_enabled = false
var spawn_mags_full_enabled = false
var spawn_weaps_with_mag_enabled = false
var spawn_ai_hotkey_enabled = false # Spawn AI at Crosshair hotkey only works while this is on
var stop_ai_spawning_enabled = false

# Internal state trackers
var _lib = null
var _ai_refresh_timer = 0.0
var _forced_sensors = {} # Sensors whose 'force' flag is switched off, so it can be restored
var _ignore_hooks_active = false
var _ignore_hook_ids = []
var _stop_spawning_hook_id = -1
var _stopped_spawner = null # The AI spawner Stop AI From Spawning turned off, so it can be turned back on
var _opening_menu = false
var was_dead = false
var noclip_enabled = false
var _was_noclip = false 

# Resume Where You Quit spawn protection
const PROTECTED_STATS = ["health", "bleeding", "fracture", "rupture", "headshot"]
var _spawn_protection_timer = 0.0
var _spawn_protection_hook_ids = []
var _protected_stats = {}

# Movement State Trackers
var _was_fast_movement = false
var _was_big_jumps = false

# MCM defaults
var key_noclip = KEY_CAPSLOCK
var key_refresh_container = KEY_KP_1 
var key_trader_restock = KEY_KP_2
var key_open_menu = KEY_KP_0
var key_spawn_ai = KEY_KP_3
var custom_walk_speed = 5.0
var custom_sprint_speed = 10.0
var custom_jump_velocity = 14.0
var spawn_protection_time = 10.0
var reset_map_loot = false
var keep_equipped_only = false
var keep_equipped_only_on_quit = false
var teleport_unlocked_shelters_only = false
var dynamic_lists_enabled = false

# UI dropdown tracking
var weather_options = ["Neutral", "Aurora", "Storm", "Rain", "Overcast", "Wind", "Fog", "Custom"]
var event_options = {"Airdrop (CASA)": "Airdrop", "Fighter Jet": "FighterJet", "Helicopter": "Helicopter", "Crash Site": "CrashSite", "BTR": "BTR", "Police (Peaceful)": "Police_Drive", "Police (Aggro)": "Police_Boss", "Bogeyman": "Bogeyman", "Driver (Bus)": "Driver", "Nomad Gathering": "Gathering", "Radio Transmission": "Transmission"}
var map_options = {"Village": "Village", "Highway": "Highway", "School": "School", "Outpost": "Outpost", "Minefield": "Minefield", "Apartments": "Apartments", "Terminal": "Terminal", "Bridge": "Bridge", "Airfield": "Airfield", "Template (Dev room)": "Template"}
var shelter_options = {"Cabin": "Cabin", "Attic": "Attic", "Classroom": "Classroom", "Tent": "Tent", "Bunker": "Bunker", "Garage": "Garage"}
var ai_type_options = {"Bandit": "bandit", "Guard": "guard", "Military": "military", "Nomad": "nomad", "Punisher (Boss)": "punisher", "Bogeyman (Boss)": "bogeyman"} # Ids are AISpawner's AI scene variables

# Selected ids of the World tab dropdowns
var sel_weather = "Neutral"
var sel_event = "Airdrop"
var sel_map = "Village"
var sel_shelter = "Cabin"
var sel_ai_type = "bandit"
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


# Sets up the Mod Configuration Menu (MCM) and registers hook callbacks with MML.
func _ready():
    load_jcm_config()
    
    if McmHelpers:
        var _config = ConfigFile.new()
        # MCM 2.8+ silently skips values missing a required property: name/tooltip/default (+ default_type/type for Keycode).
        # Keys must stay the same: they hold the player's saved values. Names, tooltips, categories and order can change freely.
        for i in MCM_CATEGORIES.size():
            _config.set_value("Category", MCM_CATEGORIES[i], {"menu_pos" = i + 1})

        _add_mcm_value(_config, "Keycode", "openMenuKey", "Hotkeys", {"name" = "Open JCM Menu", "tooltip" = "Opens the inventory with the JCM tab selected.", "default" = KEY_KP_0, "default_type" = "Key", "type" = "Key", "value" = key_open_menu})
        _add_mcm_value(_config, "Keycode", "noclipKey", "Hotkeys", {"name" = "Toggle Noclip", "tooltip" = "Turns Noclip (flight mode) on or off.", "default" = KEY_CAPSLOCK, "default_type" = "Key", "type" = "Key", "value" = key_noclip})
        _add_mcm_value(_config, "Keycode", "refreshContainerKey", "Hotkeys", {"name" = "Refresh Open Container", "tooltip" = "Re-rolls the contents of the container you're looting.", "default" = KEY_KP_1, "default_type" = "Key", "type" = "Key", "value" = key_refresh_container})
        _add_mcm_value(_config, "Keycode", "refreshTraderKey", "Hotkeys", {"name" = "Force Trader Restock", "tooltip" = "Restocks every trader on the current map.", "default" = KEY_KP_2, "default_type" = "Key", "type" = "Key", "value" = key_trader_restock})
        _add_mcm_value(_config, "Keycode", "spawnAIKey", "Hotkeys", {"name" = "Spawn AI at Crosshair", "tooltip" = "Spawns the AI type selected in JCM's AI tab where you're aiming. Only works while Spawn using Hotkey is turned on in the AI tab.", "default" = KEY_KP_3, "default_type" = "Key", "type" = "Key", "value" = key_spawn_ai})

        _add_mcm_value(_config, "Float", "walkSpeed", "Movement", {"name" = "Fast Walk Speed", "tooltip" = "Walking speed while the Fast Movement cheat is on.", "default" = 5.0, "value" = custom_walk_speed, "minRange" = 1.0, "maxRange" = 20.0})
        _add_mcm_value(_config, "Float", "sprintSpeed", "Movement", {"name" = "Fast Sprint Speed", "tooltip" = "Sprinting speed while the Fast Movement cheat is on.", "default" = 10.0, "value" = custom_sprint_speed, "minRange" = 2.0, "maxRange" = 30.0})
        _add_mcm_value(_config, "Float", "jumpVelocity", "Movement", {"name" = "Big Jump Height", "tooltip" = "Jump height while the Big Jumps cheat is on.", "default" = 14.0, "value" = custom_jump_velocity, "minRange" = 5.0, "maxRange" = 50.0})

        _add_mcm_value(_config, "Bool", "keepEquippedOnly", "Keep Gear", {"name" = "Keep Gear on Death: Equipped Only", "tooltip" = "With the Keep Gear on Death cheat on, you keep your equipped weapons and gear when you die, but lose what's in your inventory.", "default" = false, "value" = keep_equipped_only})
        _add_mcm_value(_config, "Bool", "keepEquippedOnlyOnQuit", "Keep Gear", {"name" = "Keep Gear on Quit: Equipped Only", "tooltip" = "With the Keep Gear on Quit cheat on, you keep your equipped weapons and gear when you quit outside a shelter, but lose what's in your inventory. Resume Where You Quit always keeps everything.", "default" = false, "value" = keep_equipped_only_on_quit})

        _add_mcm_value(_config, "Float", "spawnProtectionTime", "Resume Where You Quit", {"name" = "Spawn Protection on Resume", "tooltip" = "Seconds of damage immunity after loading back in where you quit. 0 turns it off.", "default" = 10.0, "value" = spawn_protection_time, "minRange" = 0.0, "maxRange" = 15.0})
        _add_mcm_value(_config, "Bool", "resetMapLoot", "Resume Where You Quit", {"name" = "Reset Map Loot on Resume", "tooltip" = "When you load back in where you quit, the map rolls fresh loot and relocks doors, like entering it normally. When off, containers, items on the ground and unlocked doors are as you left them.", "default" = false, "value" = reset_map_loot})

        _add_mcm_value(_config, "Bool", "unlockedSheltersOnly", "World", {"name" = "Teleport to Discovered Shelters Only", "tooltip" = "Go to Shelter only works for shelters you've found or unlocked.", "default" = false, "value" = teleport_unlocked_shelters_only})
        _add_mcm_value(_config, "Bool", "dynamicLists", "World", {"name" = "Dynamic Lists", "tooltip" = "Adds every map, shelter and event found in the game and registered by other mods to the World tab dropdowns, instead of only JCM's built-in lists.", "default" = false, "value" = dynamic_lists_enabled})

        # MCM 2.9+ uses one file per Metro profile (<profile>.ini, config.ini for Default). Mirrors MCM_Config.RegisterMod()
        var _default_path = FILE_PATH + "/config.ini"
        var _profile_path = FILE_PATH + "/" + _get_mcm_profile_name() + ".ini"
        DirAccess.make_dir_recursive_absolute(FILE_PATH)

        if not FileAccess.file_exists(_default_path):
            _config.save(_default_path)

        if not FileAccess.file_exists(_profile_path):
            _config.save(_profile_path)
        else:
            McmHelpers.CheckConfigurationHasUpdated(MOD_ID, _config, _profile_path)
            _config.load(_profile_path)

        McmHelpers.RegisterConfiguration(MOD_ID, "Juuzoz Cheat Menu", FILE_PATH, "In-game cheats and item spawner.", { "config.ini": Callable(self, "UpdateConfigProperties") })
        UpdateConfigProperties(_config)
        
    if Engine.has_meta("RTVModLib"):
        var lib = Engine.get_meta("RTVModLib")
        if lib.get("_is_ready"):
            _on_lib_ready()
        else:
            lib.frameworks_ready.connect(_on_lib_ready)

# Adds a value to the MCM config under a category header (MCM 2.6+). Values are shown in the order they're added.
func _add_mcm_value(config: ConfigFile, type: String, key: String, category: String, data: Dictionary):
    _mcm_menu_pos += 1
    data["category"] = category
    data["menu_pos"] = _mcm_menu_pos
    config.set_value(type, key, data)

# CurrentModLoaderProfile only exists in MCM 2.9+; older versions always use "config"
func _get_mcm_profile_name() -> String:
    var profile = McmHelpers.get("CurrentModLoaderProfile")
    if profile == null or str(profile) == "":
        return "config"
    return str(profile)

func _mcm_value(config: ConfigFile, section: String, key: String, fallback):
    if config.has_section_key(section, key):
        var entry = config.get_value(section, key)
        if entry is Dictionary and entry.has("value"):
            return entry["value"]
    return fallback

# Syncs internal variables whenever the user updates their MCM settings.
func UpdateConfigProperties(config: ConfigFile):
    key_noclip = _mcm_value(config, "Keycode", "noclipKey", key_noclip)
    key_refresh_container = _mcm_value(config, "Keycode", "refreshContainerKey", key_refresh_container)
    key_trader_restock = _mcm_value(config, "Keycode", "refreshTraderKey", key_trader_restock)
    key_open_menu = _mcm_value(config, "Keycode", "openMenuKey", key_open_menu)
    key_spawn_ai = _mcm_value(config, "Keycode", "spawnAIKey", key_spawn_ai)
    custom_walk_speed = _mcm_value(config, "Float", "walkSpeed", custom_walk_speed)
    custom_sprint_speed = _mcm_value(config, "Float", "sprintSpeed", custom_sprint_speed)
    custom_jump_velocity = _mcm_value(config, "Float", "jumpVelocity", custom_jump_velocity)
    spawn_protection_time = _mcm_value(config, "Float", "spawnProtectionTime", spawn_protection_time)
    reset_map_loot = _mcm_value(config, "Bool", "resetMapLoot", reset_map_loot)
    keep_equipped_only = _mcm_value(config, "Bool", "keepEquippedOnly", keep_equipped_only)
    keep_equipped_only_on_quit = _mcm_value(config, "Bool", "keepEquippedOnlyOnQuit", keep_equipped_only_on_quit)
    teleport_unlocked_shelters_only = _mcm_value(config, "Bool", "unlockedSheltersOnly", teleport_unlocked_shelters_only)
    dynamic_lists_enabled = _mcm_value(config, "Bool", "dynamicLists", dynamic_lists_enabled)

# Registers hooks once MML finishes initializing.
func _on_lib_ready():
    _lib = Engine.get_meta("RTVModLib")
    _lib.hook("interface-open-post", _on_interface_open)
    _lib.hook("interface-hidealltools-post", _on_interface_hide_all_tools)
    _lib.hook("interface-disabletools-post", _on_interface_tools_toggled)
    _lib.hook("interface-enabletools-post", _on_interface_tools_toggled)
    _lib.hook("settings-_ready-post", _on_settings_ready)
    _lib.hook("settings-_on_exit_menu_pressed-pre", _on_custom_exit_pressed)
    _lib.hook("settings-_on_exit_quit_pressed-pre", _on_custom_exit_pressed)
    _lib.hook("controller-_physics_process-post", _on_controller_process)
    _lib.hook("loader-validateshelter-post", _on_validate_shelter_post)
    _lib.hook("compiler-_ready-post", _on_compiler_ready_post)
    _lib.hook("compiler-spawn-pre", _on_compiler_spawn_pre)
    _handle_ai_spawning()
    print("[JCM] Cheat Menu hooks registered successfully.")


# Collects items registered by other mods from MML's internal data structures.
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

# Validates the item data before adding it to the modded dropdown.
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

# Returns true for vanilla items, which are excluded from the modded category.
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
    elif jcm_ui_instance:
        jcm_ui_instance.refresh_status()

# Hooked instead of connecting button signals because LoadDefaultTool() calls the _on_X_pressed handlers directly
func _on_interface_hide_all_tools():
    if jcm_ui_instance and jcm_ui_injected and jcm_ui_instance.has_method("_hide_panel") and not jcm_ui_instance.opening_panel:
        jcm_ui_instance._hide_panel()

func _on_interface_tools_toggled():
    if not is_instance_valid(jcm_button):
        return
    var interface_instance = _lib._caller
    var nomads_button = interface_instance.get("nomadsButton")
    if nomads_button:
        jcm_button.disabled = nomads_button.disabled

# Connects to the pause screen warning so its text can be changed.
func _on_settings_ready():
    var settings_instance = _lib._caller
    var warning_node = settings_instance.get_node_or_null("Warning")
    if warning_node and not warning_node.visibility_changed.is_connected(_on_warning_visibility_changed):
        warning_node.visibility_changed.connect(func(): _on_warning_visibility_changed(warning_node))

# Updates the quit warning text to show what JCM saves when Resume Where You Quit or Keep Gear on Quit is on.
func _on_warning_visibility_changed(warning_node):
    if not warning_node.visible: return
    var saves_spot = save_anywhere_enabled and not JCMSaveAnywhere.capture(self).is_empty()
    var labels = warning_node.find_children("*", "Label", true, false)
    for lbl in labels:
        if saves_spot:
            lbl.text = "JCM Active: Your position and gear will be saved when you quit."
            lbl.modulate = Color.GREEN
        elif keep_gear_on_quit_enabled:
            lbl.text = "JCM Active: Your gear will be safely auto-saved when you quit."
            lbl.modulate = Color.GREEN
        else:
            lbl.text = "WARNING: Unsaved progress and gear will be lost."
            lbl.modulate = Color.WHITE

# Intercepts the quit buttons. Saves character data right after the vanilla code resets it,
# and remembers the player's spot for Resume Where You Quit.
func _on_custom_exit_pressed():
    if gameData and gameData.get("tutorial") == true: return

    # Read the spot and map contents now, while the map is still loaded. Any save from an earlier quit is dropped.
    var spot = JCMSaveAnywhere.capture(self) if save_anywhere_enabled else {}
    var map_state = JCMSaveAnywhere.capture_map(self, spot["map"]) if not spot.is_empty() and not reset_map_loot else null
    JCMSaveAnywhere.clear(FILE_PATH)
    # The vanilla code already saves everything in shelters
    if gameData and gameData.get("shelter") == true: return
    if spot.is_empty() and not keep_gear_on_quit_enabled: return

    var loader = get_node_or_null("/root/Loader")
    if not loader: return

    var settings_instance = _lib._caller
    # Resume Where You Quit keeps the whole inventory, since the player continues from where they quit
    if keep_equipped_only_on_quit and spot.is_empty():
        var interface = settings_instance.get_node_or_null("../Interface")
        if interface and interface.get("inventoryGrid"):
            for item in interface.inventoryGrid.get_children():
                interface.inventoryGrid.remove_child(item)
                item.queue_free()

    await get_tree().create_timer(0.1).timeout
    if loader.has_method("SaveCharacter"):
        loader.SaveCharacter()
    if not spot.is_empty():
        JCMSaveAnywhere.store(FILE_PATH, spot, map_state)

# The main menu's Load button loads the map ValidateShelter() returns, so point it at the saved spot's map.
# gameData.menu is only true on the main menu, not on the death screen.
func _on_validate_shelter_post(_result):
    if not save_anywhere_enabled or not gameData or not gameData.menu: return null
    var spot = JCMSaveAnywhere.load_spot(self, FILE_PATH)
    if spot.is_empty(): return null
    return spot["map"]

# The map's Compiler is ready before its AI starts spawning
func _on_compiler_ready_post():
    _set_spawn_protection(false)
    if save_anywhere_enabled:
        JCMSaveAnywhere.prepare(self, FILE_PATH)

# Spawn() places the player at a transition or random waypoint. Deferred so the saved spot is applied after that.
func _on_compiler_spawn_pre():
    if save_anywhere_enabled:
        call_deferred("_apply_save_anywhere", _lib._caller)

func _apply_save_anywhere(compiler):
    if JCMSaveAnywhere.apply(self, FILE_PATH, compiler, not reset_map_loot) and spawn_protection_time > 0.0:
        _set_spawn_protection(true)

# Makes the player immune to damage for a short time after resuming. The damage hooks are only registered while it lasts,
# since Character calls the burn, poison and razor wire damage functions every frame.
func _set_spawn_protection(enabled: bool):
    if not _lib: return
    for id in _spawn_protection_hook_ids:
        _lib.unhook(id)
    _spawn_protection_hook_ids.clear()
    _protected_stats.clear()
    _spawn_protection_timer = spawn_protection_time if enabled else 0.0

    if enabled:
        var hook_ids = [
            _lib.hook("character-weapondamage-pre", _on_protected_damage_pre),
            _lib.hook("character-weapondamage-post", _on_protected_damage_post),
            _lib.hook("character-explosiondamage-pre", _on_protected_damage_pre),
            _lib.hook("character-explosiondamage-post", _on_protected_damage_post),
            _lib.hook("character-falldamage-pre", _on_protected_damage_pre),
            _lib.hook("character-falldamage-post", _on_protected_damage_post),
            _lib.hook("character-burndamage-pre", _on_protected_damage_pre),
            _lib.hook("character-burndamage-post", _on_protected_damage_post),
            _lib.hook("character-poisondamage-pre", _on_protected_damage_pre),
            _lib.hook("character-poisondamage-post", _on_protected_damage_post),
            _lib.hook("character-razordamage-pre", _on_protected_damage_pre),
            _lib.hook("character-razordamage-post", _on_protected_damage_post),
        ]
        for id in hook_ids:
            if id != -1: _spawn_protection_hook_ids.append(id)

        var loader = get_node_or_null("/root/Loader")
        if loader and loader.has_method("Message"):
            loader.Message("Spawn Protection: " + str(snappedf(spawn_protection_time, 0.1)) + "s", Color.CYAN)

# Remembers health and injuries before a damage function runs, and puts them back after, so injuries the player
# already had are kept. The damage functions take 0 to 2 arguments.
func _on_protected_damage_pre(_a = null, _b = null):
    for stat in PROTECTED_STATS:
        _protected_stats[stat] = gameData.get(stat)

func _on_protected_damage_post(_a = null, _b = null):
    for stat in _protected_stats:
        gameData.set(stat, _protected_stats[stat])
    _protected_stats.clear()

func _handle_spawn_protection(delta):
    if _spawn_protection_timer <= 0.0: return
    _spawn_protection_timer -= delta
    if _spawn_protection_timer <= 0.0:
        _set_spawn_protection(false)
        var loader = get_node_or_null("/root/Loader")
        if loader and loader.has_method("Message"):
            loader.Message("Spawn Protection Ended", Color.ORANGE)

# Main cheat loop. Runs every physics frame alongside the player's controller.
func _on_controller_process(delta):
    if not gameData: return
    
    var controller_instance = _lib._caller
    var interface = controller_instance.get_node_or_null("/root/Map/Core/UI/Interface")
    
    _handle_spawn_protection(delta)
    _handle_ai_spawning()
    _handle_invisibility(delta)
    _handle_noclip(controller_instance, delta)
    _handle_weapons_and_ammo(interface)
    _handle_vitals_and_permadeath(controller_instance)
    _handle_inventory_limits(interface)
    _handle_movement(controller_instance)
    _handle_needs_and_god_mode(controller_instance)


# Listens for direct key presses for cheats like noclip and container rerolling.
func _input(event):
    if not (event is InputEventKey or event is InputEventMouseButton) or not event.pressed:
        return

    if _hotkey_pressed(event, "noclipKey", key_noclip):
        noclip_enabled = !noclip_enabled
        save_jcm_config()
        if jcm_ui_injected and jcm_ui_instance and jcm_ui_instance.has_method("update_toggle"):
            jcm_ui_instance.update_toggle("noclip_enabled", noclip_enabled)
    if _hotkey_pressed(event, "refreshContainerKey", key_refresh_container):
        if JCMActions: JCMActions.refresh_open_container(self)
    if _hotkey_pressed(event, "refreshTraderKey", key_trader_restock):
        if JCMActions: JCMActions.force_trader_restock(self)
    if _hotkey_pressed(event, "openMenuKey", key_open_menu):
        if not get_viewport().gui_get_focus_owner() is LineEdit:
            _open_jcm_menu()
    if spawn_ai_hotkey_enabled and _hotkey_pressed(event, "spawnAIKey", key_spawn_ai):
        if not gameData.menu and not gameData.settings and not get_viewport().gui_get_focus_owner() is LineEdit:
            spawn_ai(sel_ai_type)

# Opens the inventory through the game's own "interface" action, so vanilla guards and other mods' UI changes still apply.
func _open_jcm_menu():
    if _opening_menu: return
    _opening_menu = true

    if not gameData.interface:
        for pressed in [true, false]:
            var action_event = InputEventAction.new()
            action_event.action = "interface"
            action_event.pressed = pressed
            Input.parse_input_event(action_event)

        for i in 10:
            await get_tree().process_frame
            if gameData.interface and is_instance_valid(jcm_button): break

    if gameData.interface and is_instance_valid(jcm_button) and not jcm_button.disabled and jcm_ui_instance:
        if not jcm_ui_instance.jcm_panel.is_visible_in_tree():
            jcm_ui_instance.show_panel()

    _opening_menu = false

# MCM registers each Keycode id as an InputMap action; fall back to the raw keycode when MCM isn't installed
func _hotkey_pressed(event: InputEvent, action: String, fallback_keycode: int) -> bool:
    if InputMap.has_action(action):
        return event.is_action_pressed(action)
    return event is InputEventKey and not event.echo and event.physical_keycode == fallback_keycode


# Registers the spawner hook only while Stop AI From Spawning is on, and turns the spawner back on after.
func _handle_ai_spawning():
    var hooked = _stop_spawning_hook_id != -1
    if stop_ai_spawning_enabled == hooked or not _lib: return

    if stop_ai_spawning_enabled:
        _stop_spawning_hook_id = _lib.hook("aispawner-_physics_process-pre", _on_aispawner_process_pre)
    else:
        _lib.unhook(_stop_spawning_hook_id)
        _stop_spawning_hook_id = -1
        if is_instance_valid(_stopped_spawner):
            _stopped_spawner.active = true
        _stopped_spawner = null

# AISpawner._physics_process() spawns nothing while active is off. The guards, hiders and groups that
# AISpawner.Initialize() spawns once the map's AI pools are ready don't check it, so their flags are cleared too.
func _on_aispawner_process_pre(_delta):
    var spawner = _lib._caller
    if not JCMActions.ai_enabled(spawner): return
    spawner.active = false
    spawner.initialGuard = false
    spawner.initialHider = false
    spawner.initialGroup = false
    _stopped_spawner = spawner

# Makes enemy AI ignore the player by overriding Sensor.PlayerValid(), plus extra handling for forced sensors and the BTR.
func _handle_invisibility(delta):
    if enemies_ignore_enabled != _ignore_hooks_active:
        _set_ignore_hooks(enemies_ignore_enabled)
        _ai_refresh_timer = 1.0

    _ai_refresh_timer += delta
    if _ai_refresh_timer > 0.5:
        _ai_refresh_timer = 0.0
        _refresh_ai_sensors()

# Registers the hooks only while the cheat is on.
func _set_ignore_hooks(enabled: bool):
    if not _lib: return
    _ignore_hooks_active = enabled

    for id in _ignore_hook_ids:
        _lib.unhook(id)
    _ignore_hook_ids.clear()

    if enabled:
        var hook_ids = [
            _lib.hook("sensor-playervalid-post", _on_sensor_playervalid_post, 200),
            _lib.hook("sensor-forced-post", _on_sensor_forced_post, 200),
            _lib.hook("btr-sensor-post", _on_btr_sensor_post, 200),
        ]
        for id in hook_ids:
            if id != -1: _ignore_hook_ids.append(id)

func _on_sensor_playervalid_post(_result):
    return false if enemies_ignore_enabled else null

# Forced() skips PlayerValid(), so undo what it just set.
func _on_sensor_forced_post():
    var sensor = _lib._caller
    if not enemies_ignore_enabled or not is_instance_valid(sensor): return
    sensor.PVisible = false
    sensor.priority = null

func _on_btr_sensor_post(_delta):
    var btr = _lib._caller
    if not enemies_ignore_enabled or not is_instance_valid(btr): return
    btr.playerVisible = false
    btr.lastKnownLocation = Vector3.ZERO

# Calms AI already engaged with the player, and restores forced sensors when the cheat is turned off.
func _refresh_ai_sensors():
    if not enemies_ignore_enabled:
        for sensor in _forced_sensors:
            if is_instance_valid(sensor) and is_instance_valid(sensor.owner) and not sensor.owner.dead:
                sensor.force = true
        _forced_sensors.clear()
        return

    var identifiers = get_tree().get_nodes_in_group("AI") + get_tree().get_nodes_in_group("Nomad")

    for id in identifiers:
        var ai = id.owner
        if not is_instance_valid(ai) or not "sensor" in ai or not is_instance_valid(ai.sensor):
            continue
        if ai.dead or not ai.active:
            continue
        var sensor = ai.sensor

        var engaged = false

        if sensor.force:
            _forced_sensors[sensor] = true
            sensor.force = false
            engaged = true

        var tracking_player = (is_instance_valid(sensor.priority) and sensor.priority.is_in_group("Player")) \
            or (is_instance_valid(sensor.threatPriority) and sensor.threatPriority.is_in_group("Player"))
        if tracking_player or (sensor.hot and not is_instance_valid(sensor.priority)):
            engaged = true

        if engaged:
            sensor.priority = null
            sensor.threatPriority = null
            sensor.threatTimer = 0.0
            sensor.PVisible = false
            sensor.hot = false
            sensor.hotTimer = 0.0

            var combat_states = [ai.State.Cover, ai.State.Hide, ai.State.Ambush, ai.State.Combat, ai.State.Hunt, ai.State.Defend, ai.State.Attack, ai.State.Vantage, ai.State.Grenade, ai.State.Lurk, ai.State.Switch]
            if ai.currentState in combat_states:
                ai.ChangeState("Wander")

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
        # Runs once, on the frame after the cheat is turned off.
        controller.walkSpeed = 2.5
        controller.sprintSpeed = 5.0
        _was_fast_movement = false
        
    # --- Jumps ---
    if big_jumps_enabled:
        controller.jumpVelocity = custom_jump_velocity
        _was_big_jumps = true
    elif _was_big_jumps:
        # Runs once, on the frame after the cheat is turned off.
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
func get_version_text() -> String:
    var mml_version = "?"
    var jcm_version = "?"
    if _lib:
        mml_version = _lib.version()
        var info = _lib.mod_info(MOD_ID)
        if info.has("version") and str(info["version"]) != "":
            jcm_version = str(info["version"])
    return "Metro Mod Loader " + mml_version + "  |  JCM " + jcm_version

func get_options(kind: String) -> Array:
    return JCMDynamic.options(self, kind)
func set_weather(target_weather: String):
    if JCMActions: JCMActions.set_weather(self, target_weather)
func rewind_time(travelTime: float):
    if JCMActions: JCMActions.rewind_time(self, travelTime)
func toggle_season():
    if JCMActions: JCMActions.toggle_season(self)
func force_trader_restock():
    if JCMActions: JCMActions.force_trader_restock(self)
func change_reputation(amount: float):
    if JCMActions: JCMActions.change_reputation(self, amount)
func trigger_event(func_name: String):
    if JCMActions: JCMActions.trigger_event(self, func_name)
func teleport_to_map(map_name: String):
    if JCMActions: JCMActions.teleport_to_map(self, map_name)
func teleport_to_shelter(map_name: String):
    if JCMActions: JCMActions.teleport_to_shelter(self, map_name)
func spawn_ai(ai_type: String):
    if JCMActions: JCMActions.spawn_ai(self, ai_type)
func kill_all_ai(nomads: bool):
    if JCMActions: JCMActions.kill_all_ai(self, nomads)

# The key bound to the Spawn AI at Crosshair hotkey, as shown in the AI tab (Godot names numpad keys "Kp 3")
func get_spawn_ai_key_text() -> String:
    var text = OS.get_keycode_string(key_spawn_ai)
    if InputMap.has_action("spawnAIKey"):
        var events = InputMap.action_get_events("spawnAIKey")
        if not events.is_empty():
            text = events[0].as_text().replace(" (Physical)", "")
    return text.replace("Kp ", "Numpad ")

# ==========================================
# ADDON API
# Lets other mods add toggles and buttons to the JCM menu. Documented in ADDONS.md.
# ADDON_API_VERSION is "major.minor": bump the minor version when the API gains something, and the major version
# when a change can break existing addons.
# ==========================================
const ADDON_API_VERSION = "1.0"
const BUILT_IN_TABS = ["Cheats", "Spawners", "World", "AI"]
# Any other tab name an addon uses becomes a section of this tab, which only exists while there are sections
const ADDONS_TAB = "Addons"

signal addon_toggled(id: String, enabled: bool)

var addon_states = {} # Toggle id -> bool. Saved in jcm_settings.ini, including addons that aren't installed right now
var addon_entries = [] # Registered toggles and buttons, in registration order
var _addon_states_loaded = false

# True if an addon written for the given API version ("major.minor") works with this JCM:
# the same major version, and at least that minor version.
func supports_addon_api(version: String) -> bool:
    var wanted = version.split(".")
    var current = ADDON_API_VERSION.split(".")
    if wanted[0].to_int() != current[0].to_int():
        return false
    return wanted.size() < 2 or wanted[1].to_int() <= current[1].to_int()

# Addons can register before or after JCM's _ready, so the saved states are loaded on first use instead
func load_addon_states():
    if _addon_states_loaded: return
    _addon_states_loaded = true
    if JCMConfig: JCMConfig.load_addon_states(self, FILE_PATH)

# Adds a toggle to a tab and returns true if it was added. The saved state, or default_value the first time, is
# available from is_enabled(). on_toggled(enabled: bool) runs when the player changes it.
func register_toggle(id: String, tab: String, label: String, default_value: bool = false, on_toggled: Callable = Callable()) -> bool:
    if not _addon_entry_valid(id, tab, label):
        return false
    load_addon_states()
    if not addon_states.has(id):
        addon_states[id] = default_value
    _add_addon_entry({"id": id, "tab": tab, "type": "toggle", "label": label, "callback": on_toggled})
    return true

# Adds a button to a tab and returns true if it was added. on_pressed() runs when the player presses it.
func register_button(id: String, tab: String, label: String, button_text: String, on_pressed: Callable) -> bool:
    if not _addon_entry_valid(id, tab, label):
        return false
    if not on_pressed.is_valid():
        push_warning("[JCM] Addon button '" + id + "' needs a valid on_pressed callable")
        return false
    _add_addon_entry({"id": id, "tab": tab, "type": "button", "label": label, "button_text": button_text, "callback": on_pressed})
    return true

# Removes a toggle or button. A toggle's saved state is kept.
func unregister(id: String) -> bool:
    for entry in addon_entries:
        if entry["id"] == id:
            addon_entries.erase(entry)
            _refresh_addon_ui(entry["tab"])
            return true
    return false

func is_enabled(id: String) -> bool:
    load_addon_states()
    return addon_states.get(id, false)

# Changes a registered toggle as if the player had clicked it: saves it, runs its callback and emits addon_toggled.
func set_enabled(id: String, enabled: bool) -> bool:
    var entry = _find_addon_entry(id)
    if entry.is_empty() or entry["type"] != "toggle":
        push_warning("[JCM] No addon toggle registered with the id '" + id + "'")
        return false
    if is_enabled(id) == enabled:
        return true

    addon_states[id] = enabled
    save_jcm_config()
    if jcm_ui_instance:
        jcm_ui_instance.update_addon_toggle(id, enabled)
    if entry["callback"].is_valid():
        entry["callback"].call(enabled)
    addon_toggled.emit(id, enabled)
    return true

# Sections of the Addons tab (tab names other than the built-in ones), in the order they were first used
func get_addon_sections() -> Array:
    var sections = []
    for entry in addon_entries:
        if not BUILT_IN_TABS.has(entry["tab"]) and not sections.has(entry["tab"]):
            sections.append(entry["tab"])
    return sections

func get_addon_entries(tab: String) -> Array:
    return addon_entries.filter(func(entry): return entry["tab"] == tab)

func _addon_entry_valid(id: String, tab: String, label: String) -> bool:
    if id.strip_edges() == "" or tab.strip_edges() == "" or label.strip_edges() == "":
        push_warning("[JCM] Addon entries need an id, a tab and a label")
        return false
    if not _find_addon_entry(id).is_empty():
        push_warning("[JCM] An addon entry with the id '" + id + "' is already registered")
        return false
    return true

func _find_addon_entry(id: String) -> Dictionary:
    for entry in addon_entries:
        if entry["id"] == id:
            return entry
    return {}

func _add_addon_entry(entry: Dictionary):
    addon_entries.append(entry)
    _refresh_addon_ui(entry["tab"])

# Entries can be registered while the menu is already built, e.g. by an addon that loads its features later
func _refresh_addon_ui(tab: String):
    if jcm_ui_injected and jcm_ui_instance and is_instance_valid(jcm_button):
        jcm_ui_instance.refresh_addon_tab(tab)

# ==========================================
# CONFIG WRAPPERS
# ==========================================
func load_jcm_config():
    if JCMConfig: JCMConfig.load_config(self, FILE_PATH)
func save_jcm_config():
    if JCMConfig: JCMConfig.save_config(self, FILE_PATH)