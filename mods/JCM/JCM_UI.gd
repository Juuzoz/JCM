extends Node
class_name JCMUI

var main_mod = null
var interface = null
var jcm_panel = null
var scroll_list = null
var toggle_nodes = {}
var spawner_data = [] # Tracks dropdowns for the search filter

# Injects the cheat menu into the game's existing UI structure.
func inject(mod_instance, interface_node):
    main_mod = mod_instance
    interface = interface_node
    
    var tools_node = interface.get_node_or_null("Tools")
    var crafting_node = tools_node.get_node_or_null("Crafting")
    var buttons_margin = interface.get_node_or_null("Tools/Buttons/Margin/Buttons")
    
    if not crafting_node or not buttons_margin:
        return false
        
    # Clone the vanilla crafting UI to use as the base panel
    jcm_panel = crafting_node.duplicate()
    jcm_panel.name = "JCM_Panel"
    jcm_panel.hide()
    tools_node.add_child(jcm_panel)
    
    # Move the panel up the tree to fix the invisible click shield bug
    tools_node.move_child(jcm_panel, crafting_node.get_index())
    
    # Grab the scroll list where cheat options will be populated
    scroll_list = jcm_panel.get_node("Recipes/Margin/Scroll/List")
    
    # Clears the vanilla category tabs (Consumables, Medical, etc.) and adds ours
    var cat_buttons = jcm_panel.get_node("Types/Margin/Buttons")
    for child in cat_buttons.get_children():
        child.queue_free() 
    
    _create_tab_button(cat_buttons, "Cheats")
    _create_tab_button(cat_buttons, "Spawners")
    _create_tab_button(cat_buttons, "World")
    
    # Hijack the unused 'Nomads' button on the sidebar to open the menu
    var jcm_button = buttons_margin.get_node_or_null("Nomads")
    if jcm_button:
        jcm_button.text = "JCM"
        jcm_button.disabled = false
        jcm_button.pressed.connect(_on_jcm_button_pressed)
        main_mod.jcm_button = jcm_button
        
    # Hook vanilla buttons so they automatically hide the panel when clicked
    var vanilla_buttons = ["Events", "Crafting", "Notes", "Map", "Casette"]
    for btn_name in vanilla_buttons:
        var v_btn = buttons_margin.get_node_or_null(btn_name)
        if v_btn:
            v_btn.pressed.connect(_hide_panel)
            
    # Load the default tab
    call_deferred("populate_list", "Cheats")
    return true

# ==========================================
# UI GENERATION HELPERS
# ==========================================

# Creates the top navigation buttons
func _create_tab_button(parent, tab_name):
    var btn = Button.new()
    btn.text = tab_name
    btn.custom_minimum_size = Vector2(100, 30)
    btn.pressed.connect(func(): populate_list(tab_name))
    parent.add_child(btn)

# Clears the current list and populates it based on the selected tab
func populate_list(tab_name):
    toggle_nodes.clear()

    for child in scroll_list.get_children():
        child.queue_free()
        
    if tab_name == "Cheats":
        _add_toggle("God Mode", "god_mode_enabled")
        _add_toggle("Max Needs", "max_needs_enabled")
        _add_toggle("Infinite Stamina", "infinite_stamina_enabled")
        _add_toggle("No Weight Limit", "no_weight_limit_enabled")
        _add_toggle("Fast Movement", "fast_movement_enabled")
        _add_toggle("Big Jumps", "big_jumps_enabled")
        _add_toggle("Keep Gear on Death", "keep_gear_enabled")
        _add_toggle("Keep Gear on Quit", "keep_gear_on_quit_enabled")
        _add_toggle("Disable Permadeath", "disable_permadeath_enabled")
        _add_toggle("Infinite Ammo", "infinite_ammo_enabled")
        _add_toggle("Infinite Weapon Durability", "infinite_weapon_durability_enabled")
        _add_toggle("Infinite Gear Durability", "infinite_gear_durability_enabled")
        _add_toggle("Never Jam", "never_jam_enabled")
        _add_toggle("Immortal Cat", "immortal_cat_enabled")
        
    elif tab_name == "Spawners":
        spawner_data.clear() 
        
        # Universal Search Bar
        var search_box = LineEdit.new()
        search_box.placeholder_text = "Search items..."
        search_box.custom_minimum_size = Vector2(0, 35)
        search_box.clear_button_enabled = true
        search_box.text_changed.connect(_on_search_changed)
        scroll_list.add_child(search_box)

        # Vanilla Categories
        _add_spawner("Weapon", main_mod.JCMDatabase.WEAPONS.keys(), "sel_weap")
        _add_spawner("Magazine", main_mod.JCMDatabase.MAGAZINES.keys(), "sel_mag")
        _add_spawner("Ammo (x300)", main_mod.JCMDatabase.AMMO.keys(), "sel_ammo")
        _add_spawner("Medical", main_mod.JCMDatabase.MEDICAL.keys(), "sel_med")
        _add_spawner("Gear", main_mod.JCMDatabase.GEAR.keys(), "sel_gear")
        _add_spawner("Attachment", main_mod.JCMDatabase.ATTACHMENTS.keys(), "sel_attach")
        _add_spawner("Food/Water", main_mod.JCMDatabase.FOOD.keys(), "sel_food")
        _add_spawner("Key", main_mod.JCMDatabase.KEYS.keys(), "sel_keys")
        _add_spawner("Furniture", main_mod.JCMDatabase.FURNITURE.keys(), "sel_furn")
        _add_spawner("Misc", main_mod.JCMDatabase.MISC.keys(), "sel_misc")
        # Modded Items    
        _add_spawner("Modded", main_mod.modded_items.keys(), "sel_modded")

        # Spawner modifiers
        _add_toggle("Spawn Mags Full", "spawn_mags_full_enabled")
        _add_toggle("Spawn Weapons With Mag", "spawn_weaps_with_mag_enabled")
        
    elif tab_name == "World":
        var time_btn = Button.new()
        time_btn.text = "Advance Time by 2 Hours"
        time_btn.custom_minimum_size = Vector2(0, 40)
        time_btn.pressed.connect(func(): main_mod.add_time(200.0))
        scroll_list.add_child(time_btn)

        var rewind_btn = Button.new()
        rewind_btn.text = "Rewind Time by 2 Hours"
        rewind_btn.custom_minimum_size = Vector2(0, 40)
        rewind_btn.pressed.connect(func(): main_mod.rewind_time(200.0))
        scroll_list.add_child(rewind_btn)

        var season_btn = Button.new()
        season_btn.text = "Toggle Season (Summer/Winter)"
        season_btn.custom_minimum_size = Vector2(0, 40)
        season_btn.pressed.connect(func(): main_mod.toggle_season())
        scroll_list.add_child(season_btn)

        var restock_btn = Button.new()
        restock_btn.text = "Force Trader Restock"
        restock_btn.custom_minimum_size = Vector2(0, 40)
        restock_btn.pressed.connect(func(): main_mod.force_trader_restock())
        scroll_list.add_child(restock_btn)
        
        _add_toggle("Noclip (Flight Mode)", "noclip_enabled")
        _add_toggle("Enemies Ignore Player", "enemies_ignore_enabled")
        
        # Weather Control
        var weather_hbox = HBoxContainer.new()
        var weather_opt = OptionButton.new()
        weather_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        for w in main_mod.weather_options:
            weather_opt.add_item(w)
        weather_opt.selected = main_mod.sel_weather
        weather_opt.item_selected.connect(func(idx): 
            main_mod.sel_weather = idx
            main_mod.save_jcm_config()
        )
        
        var weather_btn = Button.new()
        weather_btn.text = "Force Weather"
        
        # Tutorial safety check to prevent soft-locks
        if main_mod.gameData and main_mod.gameData.get("tutorial") == true:
            weather_btn.disabled = true
            weather_btn.text = "Locked (In Tutorial)"
        
        weather_btn.pressed.connect(func(): main_mod.set_weather(main_mod.weather_options[main_mod.sel_weather]))
        weather_hbox.add_child(weather_opt)
        weather_hbox.add_child(weather_btn)
        scroll_list.add_child(weather_hbox)
    
        # Event Spawner
        var event_hbox = HBoxContainer.new()
        var event_opt = OptionButton.new()
        event_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        
        var event_keys = main_mod.event_options.keys()
        for e in event_keys:
            event_opt.add_item(e)
            
        event_opt.selected = main_mod.sel_event
        event_opt.item_selected.connect(func(idx): 
            main_mod.sel_event = idx
            main_mod.save_jcm_config()
        )
        
        var event_btn = Button.new()
        event_btn.text = "Trigger Event"
        
        if main_mod.gameData and main_mod.gameData.get("tutorial") == true:
            event_btn.disabled = true
            event_btn.text = "Locked (In Tutorial)"
        
        event_btn.pressed.connect(func(): 
            var selected_key = event_keys[main_mod.sel_event]
            var func_name = main_mod.event_options[selected_key]
            main_mod.trigger_event(func_name)
        )
        event_hbox.add_child(event_opt)
        event_hbox.add_child(event_btn)
        scroll_list.add_child(event_hbox)

        # Map Teleporter
        var tp_hbox = HBoxContainer.new()
        var tp_opt = OptionButton.new()
        tp_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        
        var map_keys = main_mod.map_options.keys()
        for m in map_keys:
            tp_opt.add_item(m)
            
        tp_opt.selected = main_mod.sel_map
        tp_opt.item_selected.connect(func(idx): 
            main_mod.sel_map = idx
            main_mod.save_jcm_config()
        )
        
        var tp_btn = Button.new()
        tp_btn.text = "Teleport to Map"
        
        if main_mod.gameData and main_mod.gameData.get("tutorial") == true:
            tp_btn.disabled = true
            tp_btn.text = "Locked (In Tutorial)"
        
        tp_btn.pressed.connect(func(): 
            var selected_key = map_keys[main_mod.sel_map]
            var dest_map_name = main_mod.map_options[selected_key]
            main_mod.teleport_to_map(dest_map_name)
        )
        tp_hbox.add_child(tp_opt)
        tp_hbox.add_child(tp_btn)
        scroll_list.add_child(tp_hbox)

        # Shelter Teleporter
        var sh_hbox = HBoxContainer.new()
        var sh_opt = OptionButton.new()
        sh_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        
        var shelter_keys = main_mod.shelter_options.keys()
        for s in shelter_keys:
            sh_opt.add_item(s)
            
        sh_opt.selected = main_mod.sel_shelter
        sh_opt.item_selected.connect(func(idx): 
            main_mod.sel_shelter = idx
            main_mod.save_jcm_config()
        )
        
        var sh_btn = Button.new()
        sh_btn.text = "Teleport to Shelter"
        
        if main_mod.gameData and main_mod.gameData.get("tutorial") == true:
            sh_btn.disabled = true
            sh_btn.text = "Locked (In Tutorial)"
        
        sh_btn.pressed.connect(func(): 
            var selected_key = shelter_keys[main_mod.sel_shelter]
            var dest_map_name = main_mod.shelter_options[selected_key]
            main_mod.teleport_to_shelter(dest_map_name)
        )
        sh_hbox.add_child(sh_opt)
        sh_hbox.add_child(sh_btn)
        scroll_list.add_child(sh_hbox)

# Generates a CheckButton linked directly to a cheat variable in Main.gd
func _add_toggle(label_text, var_name):
    var hbox = HBoxContainer.new()
    var lbl = Label.new()
    lbl.text = label_text
    lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var toggle = CheckButton.new()
    toggle.button_pressed = main_mod.get(var_name)

    toggle_nodes[var_name] = toggle

    toggle.toggled.connect(func(toggled_on): 
        main_mod.set(var_name, toggled_on)
        main_mod.save_jcm_config()
    )
    
    hbox.add_child(lbl)
    hbox.add_child(toggle)
    scroll_list.add_child(hbox)

# Generates a dropdown menu + spawn button for an item category
func _add_spawner(label_text, item_list, selection_var):
    var hbox = HBoxContainer.new()
    
    var lbl = Label.new()
    lbl.text = "Spawn " + label_text
    lbl.custom_minimum_size = Vector2(180, 0)
    
    var opt = OptionButton.new()
    opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    # Track this dropdown so the search bar can filter it later
    spawner_data.append({
        "opt": opt,
        "full_list": item_list,
        "selection_var": selection_var
    })
    
    _populate_spawner_dropdown(opt, item_list, "")
    
    # Restore the user's previously selected item from MCM config
    var saved_real_index = main_mod.get(selection_var)
    _select_metadata_index(opt, saved_real_index)

    opt.item_selected.connect(func(idx): 
        var real_index = opt.get_item_metadata(idx)
        main_mod.set(selection_var, real_index)
        main_mod.save_jcm_config() 
    )
    
    var spawn_btn = Button.new()
    spawn_btn.text = "Spawn"
    spawn_btn.pressed.connect(func(): 
        if opt.get_item_count() == 0: return 
        
        var selected_idx = opt.get_selected()
        var real_index = opt.get_item_metadata(selected_idx)
        
        var db = main_mod.JCMDatabase
        var dict = {}
        var amt = 1
        
        # Map the UI category to the correct database dictionary
        match selection_var:
            "sel_weap": dict = db.WEAPONS
            "sel_mag": dict = db.MAGAZINES
            "sel_ammo": 
                dict = db.AMMO
                amt = 300
            "sel_med": dict = db.MEDICAL
            "sel_gear": dict = db.GEAR
            "sel_attach": dict = db.ATTACHMENTS
            "sel_food": dict = db.FOOD
            "sel_keys": dict = db.KEYS
            "sel_furn": dict = db.FURNITURE
            "sel_misc": dict = db.MISC
            "sel_modded": dict = main_mod.modded_items
            
        main_mod.spawn_item(dict, real_index, amt)
    )
    
    hbox.add_child(lbl)
    hbox.add_child(opt)
    hbox.add_child(spawn_btn)
    scroll_list.add_child(hbox)

# ==========================================
# BUTTON HOOK LOGIC
# ==========================================

# Handles opening the custom cheat panel from the sidebar
func _on_jcm_button_pressed():
    if interface.has_method("HideAllTools"):
        interface.HideAllTools()
    jcm_panel.show()
    
    var buttons_margin = interface.get_node_or_null("Tools/Buttons/Margin/Buttons")
    if buttons_margin:
        for child in buttons_margin.get_children():
            if child is BaseButton and child != main_mod.jcm_button:
                child.set_pressed_no_signal(false)
                
    main_mod.jcm_button.disabled = false
    main_mod.jcm_button.set_pressed_no_signal(true)
    
    if interface.has_method("PlayClick"):
        interface.PlayClick()

func _hide_panel():
    if jcm_panel:
        jcm_panel.hide()
    if main_mod.jcm_button:
        main_mod.jcm_button.set_pressed_no_signal(false)
        main_mod.jcm_button.disabled = false

# Updates a specific UI toggle's visual state (used when hotkeying cheats like Noclip)
func update_toggle(var_name, is_on):
    if toggle_nodes.has(var_name) and is_instance_valid(toggle_nodes[var_name]):
        toggle_nodes[var_name].set_pressed_no_signal(is_on)

# ==========================================
# SEARCH FILTERING HELPERS
# ==========================================

# Rebuilds the dropdown items based on the search query.
# Stores the item's original array index in metadata so it always spawns the correct item
# even when the visual list is filtered.
func _populate_spawner_dropdown(opt: OptionButton, full_list: Array, filter_text: String):
    opt.clear()
    filter_text = filter_text.to_lower()
    
    for i in range(full_list.size()):
        var item_name = full_list[i]
        if filter_text == "" or filter_text in item_name.to_lower():
            opt.add_item(item_name)
            opt.set_item_metadata(opt.get_item_count() - 1, i)

# Searches the current filtered list to re-highlight the user's previously saved selection
func _select_metadata_index(opt: OptionButton, target_real_index: int):
    for i in range(opt.get_item_count()):
        if opt.get_item_metadata(i) == target_real_index:
            opt.selected = i
            return
            
    if opt.get_item_count() > 0:
        opt.selected = 0 

# Triggers whenever the user types in the search bar
func _on_search_changed(new_text: String):
    for data in spawner_data:
        var opt = data["opt"]
        var full_list = data["full_list"]
        var selection_var = data["selection_var"]
        
        _populate_spawner_dropdown(opt, full_list, new_text)
        
        var saved_real_index = main_mod.get(selection_var)
        _select_metadata_index(opt, saved_real_index)