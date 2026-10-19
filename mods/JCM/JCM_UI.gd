extends Node
class_name JCMUI

var main_mod = null
var interface = null
var jcm_panel = null
var scroll_list = null
var toggle_nodes = {}
const LABEL_WIDTH = 140
const BUTTON_WIDTH = 100
const STEP_WIDTH = 50

var rep_label = null
var time_label = null
var day_label = null
var day_back_button = null
var current_tab = "Cheats"
var lists_dynamic = false # Whether the current tab's dropdowns were built with Dynamic Lists on
var season_label = null
var spawn_key_label = null
var spawner_data = [] # Tracks dropdowns for the search filter
var tab_bar = null
var tab_buttons = {} # Tab name -> its button
var opening_panel = false # True while the JCM button is calling HideAllTools()

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
    
    # Place the panel at the crafting panel's position in the tree so an invisible node doesn't block clicks
    tools_node.move_child(jcm_panel, crafting_node.get_index())
    
    # The scroll list that holds the cheat options
    scroll_list = jcm_panel.get_node("Recipes/Margin/Scroll/List")
    scroll_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    
    # Replaces the vanilla category tabs (Consumables, Medical, etc.) with the JCM tabs
    tab_bar = jcm_panel.get_node("Types/Margin/Buttons")
    for child in tab_bar.get_children():
        child.queue_free()

    for tab_name in main_mod.BUILT_IN_TABS:
        _create_tab_button(tab_bar, tab_name)
    if not main_mod.get_addon_sections().is_empty():
        _create_tab_button(tab_bar, main_mod.ADDONS_TAB)

    _create_sidebar_button(buttons_margin)

    # Hook vanilla buttons so they automatically hide the panel when clicked
    var vanilla_buttons = ["Events", "Crafting", "Notes", "Map", "Casette", "Nomads"]
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

# Fresh Button (not a duplicate of a vanilla one) so it never inherits a vanilla tool's pressed connection
func _create_sidebar_button(buttons_margin):
    var jcm_button = Button.new()
    jcm_button.name = "JCM"
    jcm_button.text = "JCM"
    jcm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    jcm_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
    jcm_button.toggle_mode = true

    var ref_button = buttons_margin.get_node_or_null("Events")
    if ref_button:
        jcm_button.button_group = ref_button.button_group

    var rows_before = _count_grid_rows(buttons_margin)
    buttons_margin.add_child(jcm_button)
    jcm_button.pressed.connect(_on_jcm_button_pressed)
    main_mod.jcm_button = jcm_button

    # Add columns instead of a new row so the sidebar keeps its original height
    var button_count = _count_visible_children(buttons_margin)
    while rows_before > 0 and _count_grid_rows(buttons_margin) > rows_before and buttons_margin.columns < button_count:
        buttons_margin.columns += 1

    var rows_after = _count_grid_rows(buttons_margin)
    var panel = interface.get_node_or_null("Tools/Buttons")
    var margin = buttons_margin.get_parent()
    if panel and margin and rows_before > 0 and rows_after > rows_before:
        var v_sep = buttons_margin.get_theme_constant("v_separation")
        var margin_total = margin.get_theme_constant("margin_top") + margin.get_theme_constant("margin_bottom")
        var grid_height = panel.offset_bottom - panel.offset_top - margin_total
        var row_height = (grid_height - v_sep * (rows_before - 1)) / float(rows_before)
        panel.offset_bottom += (rows_after - rows_before) * (row_height + v_sep)

func _count_visible_children(grid):
    var visible_count = 0
    for child in grid.get_children():
        if child is Control and child.visible:
            visible_count += 1
    return visible_count

func _count_grid_rows(grid):
    return int(ceil(_count_visible_children(grid) / float(max(grid.columns, 1))))

# Creates the top navigation buttons
# Tabs share the bar's width equally, like the vanilla crafting tabs. Names that don't fit are cut short,
# with the full name in the tooltip, so addon tabs can't push the bar past the panel's edge.
func _create_tab_button(parent, tab_name):
    var btn = Button.new()
    btn.text = tab_name
    btn.tooltip_text = tab_name
    btn.custom_minimum_size = Vector2(0, 30)
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.clip_text = true
    btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    btn.pressed.connect(func(): populate_list(tab_name))
    parent.add_child(btn)
    tab_buttons[tab_name] = btn
    _update_tab_columns()

# The bar is a GridContainer; one column per tab keeps every tab on one row
func _update_tab_columns():
    if is_instance_valid(tab_bar) and tab_bar is GridContainer:
        tab_bar.columns = max(1, tab_buttons.size())

# Clears the current list and populates it based on the selected tab
func populate_list(tab_name):
    current_tab = tab_name
    lists_dynamic = main_mod.dynamic_lists_enabled
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
        _add_toggle("Resume Where You Quit", "save_anywhere_enabled")
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
        _add_spawner("Primary", main_mod.JCMDatabase.PRIMARY_WEAPONS.keys(), "sel_primary")
        _add_spawner("Secondary", main_mod.JCMDatabase.SECONDARY_WEAPONS.keys(), "sel_secondary")
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
        _add_day_row()
        _add_time_row()
        _add_season_row()
        _add_dropdown_row("Weather", main_mod.get_options("weather"), "sel_weather", "Set",
            func(id): main_mod.set_weather(id))
        scroll_list.add_child(HSeparator.new())

        _add_dropdown_row("Event", main_mod.get_options("events"), "sel_event", "Trigger",
            func(id): main_mod.trigger_event(id))
        _add_reputation_row()
        _add_action_row("Traders", "Restock", func(): main_mod.force_trader_restock())
        scroll_list.add_child(HSeparator.new())

        _add_dropdown_row("Go to Map", main_mod.get_options("maps"), "sel_map", "Teleport",
            func(id): main_mod.teleport_to_map(id))
        _add_dropdown_row("Go to Shelter", main_mod.get_options("shelters"), "sel_shelter", "Teleport",
            func(id): main_mod.teleport_to_shelter(id))
        scroll_list.add_child(HSeparator.new())

        _add_toggle("Noclip (Flight Mode)", "noclip_enabled")

    elif tab_name == "AI":
        _add_note("Spawns AI where your crosshair is pointing.")
        _add_dropdown_row("Spawn AI", main_mod.get_options("ai_types"), "sel_ai_type", "Spawn",
            func(id): main_mod.spawn_ai(id))
        _add_toggle("Spawn using Hotkey", "spawn_ai_hotkey_enabled", func(_on): refresh_spawn_key())
        spawn_key_label = _add_note("")
        refresh_spawn_key()
        scroll_list.add_child(HSeparator.new())

        _add_action_row("Kill All Enemies", "Kill", func(): main_mod.kill_all_ai(false))
        _add_action_row("Kill All Nomads", "Kill", func(): main_mod.kill_all_ai(true))
        _add_toggle("Stop AI From Spawning", "stop_ai_spawning_enabled")
        _add_toggle("Enemies Ignore Player", "enemies_ignore_enabled")

    elif tab_name == main_mod.ADDONS_TAB:
        _add_addon_sections()

    if main_mod.BUILT_IN_TABS.has(tab_name):
        var entries = main_mod.get_addon_entries(tab_name)
        if not entries.is_empty():
            scroll_list.add_child(HSeparator.new())
            _add_addon_rows(entries)
    _add_footer()

# ==========================================
# ADDON ENTRIES
# Toggles and buttons registered by other mods through the addon API in Main.gd
# ==========================================

# The Addons tab: one titled section per tab name addons used, so any number of addons fit in one tab
func _add_addon_sections():
    var first = true
    for section in main_mod.get_addon_sections():
        if not first:
            scroll_list.add_child(HSeparator.new())
        first = false

        var header = Label.new()
        header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _fit_text(header, section)
        scroll_list.add_child(header)
        _add_addon_rows(main_mod.get_addon_entries(section))

func _add_addon_rows(entries):
    for entry in entries:
        var id = entry["id"]
        if entry["type"] == "toggle":
            _add_toggle_row(entry["label"], main_mod.is_enabled(id), addon_toggle_key(id),
                func(on): main_mod.set_enabled(id, on))
        else:
            var callback: Callable = entry["callback"]
            _add_action_row(entry["label"], entry["button_text"], func(): if callback.is_valid(): callback.call())

# Keeps addon ids apart from the Main.gd variable names that built-in toggles are stored under
static func addon_toggle_key(id) -> String:
    return "addon:" + id

func update_addon_toggle(id, is_on):
    update_toggle(addon_toggle_key(id), is_on)

# Called when an addon registers or removes an entry while the menu exists.
# tab_name is the entry's tab: a built-in tab, or a section of the Addons tab.
func refresh_addon_tab(tab_name):
    if not is_instance_valid(tab_bar):
        return
    var addons_tab = main_mod.ADDONS_TAB

    if main_mod.BUILT_IN_TABS.has(tab_name):
        if current_tab == tab_name:
            populate_list(tab_name)
        return

    # The Addons tab is shown only while it has sections
    var has_sections = not main_mod.get_addon_sections().is_empty()
    if has_sections and not tab_buttons.has(addons_tab):
        _create_tab_button(tab_bar, addons_tab)
    elif not has_sections and tab_buttons.has(addons_tab):
        tab_buttons[addons_tab].queue_free()
        tab_buttons.erase(addons_tab)
        _update_tab_columns()
        if current_tab == addons_tab:
            populate_list("Cheats")
            return

    if current_tab == addons_tab:
        populate_list(addons_tab)

# Greyed-out, wrapping explanation text
func _add_note(text) -> Label:
    var note = Label.new()
    note.text = text
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.modulate = Color(0.8, 0.8, 0.8)
    scroll_list.add_child(note)
    return note

# Shows which key spawns AI while the Spawn using Hotkey toggle is on. The key can change in MCM, so this also runs on refresh.
func refresh_spawn_key():
    if not is_instance_valid(spawn_key_label): return
    spawn_key_label.visible = main_mod.spawn_ai_hotkey_enabled
    spawn_key_label.text = "Press " + main_mod.get_spawn_ai_key_text() + " to spawn the selected AI at your crosshair. The key can be changed in MCM."

# Greyed-out version line at the bottom of each tab. The spacer keeps it at the bottom on short tabs.
func _add_footer():
    var spacer = Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll_list.add_child(spacer)

    var footer = Label.new()
    footer.text = main_mod.get_version_text()
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.modulate = Color(0.6, 0.6, 0.6)
    scroll_list.add_child(footer)

# ==========================================
# WORLD TAB ROW HELPERS
# Every row is: title | value or dropdown (expands) | button(s)
# ==========================================

func _add_row(title) -> HBoxContainer:
    var hbox = HBoxContainer.new()
    var lbl = Label.new()
    lbl.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
    _fit_text(lbl, title)
    hbox.add_child(lbl)
    scroll_list.add_child(hbox)
    return hbox

func _make_value_label() -> Label:
    var lbl = Label.new()
    lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    lbl.clip_text = true
    lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    return lbl

func _make_button(text, width, on_press) -> Button:
    var btn = Button.new()
    btn.custom_minimum_size = Vector2(width, 0)
    _fit_text(btn, text)
    btn.pressed.connect(on_press)
    return btn

# Text that doesn't fit is cut short with an ellipsis and shown in full as a tooltip. Without this, a Label or Button
# asks for its whole text's width, which widens the entire list and pushes every row's buttons past the panel's edge.
func _fit_text(control: Control, text):
    control.text = text
    control.tooltip_text = text
    control.clip_text = true
    control.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    if control is Label:
        control.mouse_filter = Control.MOUSE_FILTER_PASS # Labels ignore the mouse by default, which hides tooltips

func _add_day_row():
    var hbox = _add_row("Day")
    day_label = _make_value_label()
    hbox.add_child(day_label)

    for days in [-1, 1]:
        var shift_day = func():
            if days < 0: main_mod.rewind_time(-days * 2400.0)
            else: main_mod.add_time(days * 2400.0)
            refresh_time()
        var day_btn = _make_button("%+d" % days, STEP_WIDTH, shift_day)
        if days < 0: day_back_button = day_btn
        hbox.add_child(day_btn)

func _add_time_row():
    var hbox = _add_row("Time")
    time_label = _make_value_label()
    hbox.add_child(time_label)

    for hours in [-10, -1, 1, 10]:
        var shift_time = func():
            if hours < 0: main_mod.rewind_time(-hours * 100.0)
            else: main_mod.add_time(hours * 100.0)
            refresh_time()
        hbox.add_child(_make_button("%+d" % hours, STEP_WIDTH, shift_time))

    refresh_time()

func _add_season_row():
    var hbox = _add_row("Season")
    season_label = _make_value_label()
    hbox.add_child(season_label)

    var toggle_season = func():
        main_mod.toggle_season()
        refresh_season()
    hbox.add_child(_make_button("Toggle", BUTTON_WIDTH, toggle_season))

    refresh_season()

func _add_reputation_row():
    var hbox = _add_row("Reputation")
    rep_label = _make_value_label()
    hbox.add_child(rep_label)

    for amount in [-10, 10]:
        var change_rep = func():
            main_mod.change_reputation(float(amount))
            refresh_reputation()
        hbox.add_child(_make_button("%+d" % amount, STEP_WIDTH, change_rep))

    refresh_reputation()

# The title takes the free space, so long titles aren't cut short, and the button stays at the right edge
func _add_action_row(title, button_text, on_press):
    var hbox = _add_row(title)
    hbox.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(_make_button(button_text, BUTTON_WIDTH, on_press))

# Dropdown of {"label", "id"} options. The selected id is saved to selection_var in Main.gd and passed to on_press.
func _add_dropdown_row(title, options, selection_var, button_text, on_press, lock_in_tutorial = true):
    var hbox = _add_row(title)

    var opt = OptionButton.new()
    opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    opt.fit_to_longest_item = false
    opt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    for entry in options:
        opt.add_item(entry["label"])
        opt.set_item_metadata(opt.item_count - 1, entry["id"])

    var saved_id = main_mod.get(selection_var)
    for i in opt.item_count:
        if opt.get_item_metadata(i) == saved_id:
            opt.selected = i
            break

    opt.item_selected.connect(func(idx):
        main_mod.set(selection_var, opt.get_item_metadata(idx))
        main_mod.save_jcm_config()
    )

    var run = func(): on_press.call(opt.get_item_metadata(opt.selected))
    var btn = _make_button(button_text, BUTTON_WIDTH, run)

    # Tutorial safety check to prevent soft-locks
    if lock_in_tutorial and main_mod.gameData and main_mod.gameData.get("tutorial") == true:
        btn.disabled = true
        btn.text = "Locked"
        btn.tooltip_text = "Unavailable in the tutorial"

    hbox.add_child(opt)
    hbox.add_child(btn)

func refresh_status():
    if lists_dynamic != main_mod.dynamic_lists_enabled:
        populate_list(current_tab)
        return

    refresh_reputation()
    refresh_time()
    refresh_season()
    refresh_spawn_key()

func refresh_season():
    if not is_instance_valid(season_label): return
    var sim = main_mod.get_node_or_null("/root/Simulation")
    if not sim:
        season_label.text = "?"
        return
    season_label.text = "Winter" if sim.season == 2 else "Summer"

func refresh_time():
    if not is_instance_valid(time_label): return
    var sim = main_mod.get_node_or_null("/root/Simulation")
    if not sim:
        time_label.text = "?"
        if is_instance_valid(day_label): day_label.text = "?"
        return

    var hours = int(sim.time / 100.0)
    var minutes = int(floor(float(int(sim.time) % 100) / 5.0) * 5)
    if minutes >= 60:
        minutes = 0
        hours += 1

    time_label.text = "%02d:%02d" % [hours % 24, minutes]
    if is_instance_valid(day_label):
        day_label.text = "%d - %s" % [sim.day, sim.Weekday()]
    if is_instance_valid(day_back_button):
        day_back_button.disabled = sim.day <= 1

func refresh_reputation():
    if not is_instance_valid(rep_label): return
    var reputation = main_mod.gameData.get("reputation") if main_mod.gameData else null
    if reputation == null:
        rep_label.text = "?"
        rep_label.remove_theme_color_override("font_color")
        return
    rep_label.text = str(int(round(reputation)))
    rep_label.add_theme_color_override("font_color", Color.GREEN if reputation >= 50.0 else Color.RED)

# Generates a CheckButton linked directly to a cheat variable in Main.gd. on_toggled, if given, runs after the change.
func _add_toggle(label_text, var_name, on_toggled = null):
    _add_toggle_row(label_text, main_mod.get(var_name), var_name, func(toggled_on):
        main_mod.set(var_name, toggled_on)
        main_mod.save_jcm_config()
        if on_toggled: on_toggled.call(toggled_on)
    )

# A label and a CheckButton. key is what update_toggle() finds the CheckButton by.
func _add_toggle_row(label_text, is_on, key, on_toggled: Callable):
    var hbox = HBoxContainer.new()
    var lbl = Label.new()
    lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _fit_text(lbl, label_text)

    var toggle = CheckButton.new()
    toggle.button_pressed = is_on
    toggle_nodes[key] = toggle
    toggle.toggled.connect(on_toggled)

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
    
    # Truncates long item names in the spawner
    opt.fit_to_longest_item = false 
    opt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

    
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
            "sel_primary": dict = db.PRIMARY_WEAPONS
            "sel_secondary": dict = db.SECONDARY_WEAPONS
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
    # HideAllTools is hooked to hide the JCM panel, so flag that this call comes from the JCM button
    opening_panel = true
    if interface.has_method("HideAllTools"):
        interface.HideAllTools()
    opening_panel = false
    jcm_panel.show()
    
    var buttons_margin = interface.get_node_or_null("Tools/Buttons/Margin/Buttons")
    if buttons_margin:
        for child in buttons_margin.get_children():
            if child is BaseButton and child != main_mod.jcm_button:
                child.set_pressed_no_signal(false)
                
    main_mod.jcm_button.set_pressed_no_signal(true)
    
    if interface.has_method("PlayClick"):
        interface.PlayClick()

func show_panel():
    _on_jcm_button_pressed()

func _hide_panel():
    if jcm_panel:
        jcm_panel.hide()
    if is_instance_valid(main_mod.jcm_button):
        main_mod.jcm_button.set_pressed_no_signal(false)

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
        
        # --- DETECT CATEGORY HEADERS ---
        if item_name.begins_with("--") and item_name.ends_with("--"):
            # Only show headers if the search bar is empty
            if filter_text == "":
                # Strip the "--" and spaces so Godot can style it natively
                var clean_name = item_name.replace("--", "").strip_edges()
                
                # add_separator shows the text centered between lines and makes it unselectable
                opt.add_separator(clean_name) 
                
                # The metadata index is still tracked so the search filter keeps working
                var new_idx = opt.get_item_count() - 1
                opt.set_item_metadata(new_idx, i)
            continue 
        # --------------------------------
            
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