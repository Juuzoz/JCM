extends Node
class_name JCMDynamicLists

# Option lists for the World tab dropdowns. Entries are {"label": String, "id": String}.
# The built-in lists are always included. With Dynamic Lists on, ids found in the game and registered by mods are added after them.

const NON_MAP_SCENES = ["Menu", "Intro", "Death", "Tutorial"]
const SKIPPED_EVENTS = ["Police"] # Covered by the custom Police (Peaceful) and Police (Aggro) entries
const EVENT_LABELS = {"ActivateTrader": "Activate Traders", "DeactivateTrader": "Deactivate Traders", "Cat": "Missing Cat"}

# kind: "weather", "events", "maps", "shelters" or "ai_types". Weather and AI types always use the built-in list,
# since their entries are hardcoded in World.gd and AISpawner.gd.
static func options(mod: Node, kind: String) -> Array:
    var entries = builtin_options(mod, kind)
    if not mod.dynamic_lists_enabled:
        return entries

    var known = {}
    for entry in entries:
        known[entry["id"]] = true

    var extras = []
    for entry in _discover(mod, kind):
        if entry["id"] != "" and not known.has(entry["id"]):
            known[entry["id"]] = true
            extras.append(entry)

    extras.sort_custom(func(a, b): return a["label"].to_lower() < b["label"].to_lower())
    return entries + extras

static func builtin_options(mod: Node, kind: String) -> Array:
    match kind:
        "weather": return _labeled(mod.weather_options)
        "events": return _from_labels(mod.event_options)
        "maps": return _from_labels(mod.map_options)
        "shelters": return _from_labels(mod.shelter_options)
        "ai_types": return _from_labels(mod.ai_type_options)
    return []

static func _discover(mod: Node, kind: String) -> Array:
    match kind:
        "events": return _event_entries(mod)
        "maps": return _labeled(_map_ids(mod))
        "shelters": return _labeled(_shelter_ids(mod))
    return []

static func _labeled(ids: Array) -> Array:
    var entries = []
    for id in ids:
        entries.append({"label": str(id), "id": str(id)})
    return entries

static func _from_labels(labels: Dictionary) -> Array:
    var entries = []
    for label in labels:
        entries.append({"label": label, "id": labels[label]})
    return entries

static func _registry_keys(mod: Node, registry: String, include_vanilla: bool = true) -> Array:
    var lib = mod._lib
    if lib == null or not lib.has_method("keys"):
        return []
    return lib.keys(registry, include_vanilla)

# Mod maps share Loader.shelters with shelters, so they are filtered out using the maps registry.
static func _shelter_ids(mod: Node) -> Array:
    var ids = mod.shelter_options.values()
    ids.append_array(_registry_keys(mod, "shelters"))

    var loader = mod.get_node_or_null("/root/Loader")
    if loader:
        var listed = loader.get("shelters")
        if listed == null and loader.get_script():
            listed = loader.get_script().get_script_constant_map().get("shelters")

        if listed is Array:
            var mod_maps = _registry_keys(mod, "maps", false)
            for id in listed:
                if not ids.has(id) and not mod_maps.has(id):
                    ids.append(id)
    return ids

# Every named scene path (vanilla and mod) that is not a shelter or a menu-type scene.
static func _map_ids(mod: Node) -> Array:
    var shelters = _shelter_ids(mod)
    var ids = []
    for id in _registry_keys(mod, "scene_paths"):
        if not NON_MAP_SCENES.has(id) and not shelters.has(id):
            ids.append(id)

    for id in _registry_keys(mod, "maps", false):
        if not ids.has(id):
            ids.append(id)
    return ids

# Events.tres holds vanilla and mod-registered events. Each names a no-argument EventSystem method.
static func _event_entries(mod: Node) -> Array:
    var entries = []
    var event_list = load("res://Events/Events.tres")
    if event_list == null or not (event_list.get("events") is Array):
        return entries

    var event_sys = null
    var map_node = mod.get_node_or_null("/root/Map")
    if map_node:
        event_sys = mod.JCMActions._get_event_system(map_node)

    for event in event_list.events:
        if event == null:
            continue

        var function_name = str(event.get("function"))
        if function_name == "" or SKIPPED_EVENTS.has(function_name):
            continue
        if event_sys and not event_sys.has_method(function_name):
            continue

        var label = EVENT_LABELS.get(function_name, str(event.get("name")))
        entries.append({"label": label if label != "" else function_name, "id": function_name})
    return entries
