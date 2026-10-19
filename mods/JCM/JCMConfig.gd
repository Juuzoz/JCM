extends Node
class_name JCMConfigManager

# World tab dropdown selections are saved as ids. Configs from before 3.2.0 saved an index into the built-in list.
static func _load_selection(config: ConfigFile, mod: Node, key: String, kind: String) -> String:
    var saved = config.get_value("Spawners", key, 0)
    if saved is String:
        return saved

    var builtin = mod.JCMDynamic.builtin_options(mod, kind)
    if saved is int and saved >= 0 and saved < builtin.size():
        return builtin[saved]["id"]
    return builtin[0]["id"]

static func load_config(mod: Node, file_path: String):
    var config = ConfigFile.new()
    if config.load(file_path + "/jcm_settings.ini") == OK:
        mod.noclip_enabled = config.get_value("Cheats", "noclip_enabled", false)
        mod.god_mode_enabled = config.get_value("Cheats", "god_mode_enabled", false)
        mod.enemies_ignore_enabled = config.get_value("Cheats", "enemies_ignore_enabled", false)
        mod.max_needs_enabled = config.get_value("Cheats", "max_needs_enabled", false)
        mod.infinite_stamina_enabled = config.get_value("Cheats", "infinite_stamina_enabled", false)
        mod.no_weight_limit_enabled = config.get_value("Cheats", "no_weight_limit_enabled", false)
        mod.fast_movement_enabled = config.get_value("Cheats", "fast_movement_enabled", false)
        mod.big_jumps_enabled = config.get_value("Cheats", "big_jumps_enabled", false)
        mod.keep_gear_enabled = config.get_value("Cheats", "keep_gear_enabled", false)
        mod.keep_gear_on_quit_enabled = config.get_value("Cheats", "keep_gear_on_quit_enabled", false)
        mod.save_anywhere_enabled = config.get_value("Cheats", "save_anywhere_enabled", false)
        mod.disable_permadeath_enabled = config.get_value("Cheats", "disable_permadeath_enabled", false)
        mod.infinite_ammo_enabled = config.get_value("Cheats", "infinite_ammo_enabled", false)
        mod.infinite_weapon_durability_enabled = config.get_value("Cheats", "infinite_weapon_durability_enabled", false)
        mod.infinite_gear_durability_enabled = config.get_value("Cheats", "infinite_gear_durability_enabled", false)
        mod.never_jam_enabled = config.get_value("Cheats", "never_jam_enabled", false)
        mod.immortal_cat_enabled = config.get_value("Cheats", "immortal_cat_enabled", false)
        mod.stop_ai_spawning_enabled = config.get_value("Cheats", "stop_ai_spawning_enabled", false)
        mod.spawn_mags_full_enabled = config.get_value("Spawners", "spawn_mags_full_enabled", false)
        mod.spawn_weaps_with_mag_enabled = config.get_value("Spawners", "spawn_weaps_with_mag_enabled", false)
        mod.spawn_ai_hotkey_enabled = config.get_value("Spawners", "spawn_ai_hotkey_enabled", false)
        
        mod.sel_weather = _load_selection(config, mod, "sel_weather", "weather")
        mod.sel_event = _load_selection(config, mod, "sel_event", "events")
        mod.sel_map = _load_selection(config, mod, "sel_map", "maps")
        mod.sel_shelter = _load_selection(config, mod, "sel_shelter", "shelters")
        mod.sel_ai_type = _load_selection(config, mod, "sel_ai_type", "ai_types")
        mod.sel_primary = config.get_value("Spawners", "sel_primary", 0)
        mod.sel_secondary = config.get_value("Spawners", "sel_secondary", 0)
        mod.sel_mag = config.get_value("Spawners", "sel_mag", 0)
        mod.sel_ammo = config.get_value("Spawners", "sel_ammo", 0)
        mod.sel_med = config.get_value("Spawners", "sel_med", 0)
        mod.sel_gear = config.get_value("Spawners", "sel_gear", 0)
        mod.sel_attach = config.get_value("Spawners", "sel_attach", 0)
        mod.sel_food = config.get_value("Spawners", "sel_food", 0)
        mod.sel_keys = config.get_value("Spawners", "sel_keys", 0)
        mod.sel_furn = config.get_value("Spawners", "sel_furn", 0)
        mod.sel_misc = config.get_value("Spawners", "sel_misc", 0)
        mod.sel_modded = config.get_value("Spawners", "sel_modded", 0)

# Addon toggle states. States changed since startup are kept over the saved ones.
static func load_addon_states(mod: Node, file_path: String):
    var config = ConfigFile.new()
    if config.load(file_path + "/jcm_settings.ini") != OK or not config.has_section("Addons"):
        return
    for id in config.get_section_keys("Addons"):
        if not mod.addon_states.has(id):
            mod.addon_states[id] = config.get_value("Addons", id) == true

static func save_config(mod: Node, file_path: String):
    var config = ConfigFile.new()
    config.set_value("Cheats", "noclip_enabled", mod.noclip_enabled)
    config.set_value("Cheats", "god_mode_enabled", mod.god_mode_enabled)
    config.set_value("Cheats", "enemies_ignore_enabled", mod.enemies_ignore_enabled)
    config.set_value("Cheats", "max_needs_enabled", mod.max_needs_enabled)
    config.set_value("Cheats", "infinite_stamina_enabled", mod.infinite_stamina_enabled)
    config.set_value("Cheats", "no_weight_limit_enabled", mod.no_weight_limit_enabled)
    config.set_value("Cheats", "fast_movement_enabled", mod.fast_movement_enabled)
    config.set_value("Cheats", "big_jumps_enabled", mod.big_jumps_enabled)
    config.set_value("Cheats", "keep_gear_enabled", mod.keep_gear_enabled)
    config.set_value("Cheats", "keep_gear_on_quit_enabled", mod.keep_gear_on_quit_enabled)
    config.set_value("Cheats", "save_anywhere_enabled", mod.save_anywhere_enabled)
    config.set_value("Cheats", "disable_permadeath_enabled", mod.disable_permadeath_enabled)
    config.set_value("Cheats", "infinite_ammo_enabled", mod.infinite_ammo_enabled)
    config.set_value("Cheats", "infinite_weapon_durability_enabled", mod.infinite_weapon_durability_enabled)
    config.set_value("Cheats", "infinite_gear_durability_enabled", mod.infinite_gear_durability_enabled)
    config.set_value("Cheats", "never_jam_enabled", mod.never_jam_enabled)
    config.set_value("Cheats", "immortal_cat_enabled", mod.immortal_cat_enabled)
    config.set_value("Cheats", "stop_ai_spawning_enabled", mod.stop_ai_spawning_enabled)
    config.set_value("Spawners", "spawn_mags_full_enabled", mod.spawn_mags_full_enabled)
    config.set_value("Spawners", "spawn_weaps_with_mag_enabled", mod.spawn_weaps_with_mag_enabled)
    config.set_value("Spawners", "spawn_ai_hotkey_enabled", mod.spawn_ai_hotkey_enabled)
    
    config.set_value("Spawners", "sel_weather", mod.sel_weather)
    config.set_value("Spawners", "sel_event", mod.sel_event)
    config.set_value("Spawners", "sel_map", mod.sel_map)
    config.set_value("Spawners", "sel_shelter", mod.sel_shelter)
    config.set_value("Spawners", "sel_ai_type", mod.sel_ai_type)
    config.set_value("Spawners", "sel_primary", mod.sel_primary)
    config.set_value("Spawners", "sel_secondary", mod.sel_secondary)
    config.set_value("Spawners", "sel_mag", mod.sel_mag)
    config.set_value("Spawners", "sel_ammo", mod.sel_ammo)
    config.set_value("Spawners", "sel_med", mod.sel_med)
    config.set_value("Spawners", "sel_gear", mod.sel_gear)
    config.set_value("Spawners", "sel_attach", mod.sel_attach)
    config.set_value("Spawners", "sel_food", mod.sel_food)
    config.set_value("Spawners", "sel_keys", mod.sel_keys)
    config.set_value("Spawners", "sel_furn", mod.sel_furn)
    config.set_value("Spawners", "sel_misc", mod.sel_misc)
    config.set_value("Spawners", "sel_modded", mod.sel_modded)

    # Loaded first, so saving before any addon has registered doesn't drop their states
    mod.load_addon_states()
    for id in mod.addon_states:
        config.set_value("Addons", id, mod.addon_states[id])

    config.save(file_path + "/jcm_settings.ini")