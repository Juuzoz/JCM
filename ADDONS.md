# Making JCM Addons

An addon is a separate mod that adds its own toggles and buttons to the Juuzoz Cheat Menu (JCM). JCM shows them in its menu and saves the toggle states. The addon does the cheat itself, usually with Metro Mod Loader hooks, the same way JCM does.

Content needs no addon API: items, maps, shelters and events registered through the mod loader's registry already show up in JCM (the Modded spawner, and the World tab with Dynamic Lists on).

## Setup

Require JCM in your `mod.txt`, so the mod loader loads JCM first and skips your addon when JCM isn't installed:

```ini
[mod]
name="Moon Gravity for JCM"
id="jcm-moon-gravity"
version="1.0.0"

[dependencies]
required=["juuzoz-jcm"]

[autoload]
JCMMoonGravity="res://JCMMoonGravity/Main.gd"
```

JCM is the autoload node `/root/jcm`. Players can still force-load your addon without JCM ("Load anyway" in the Mods tab), and an older JCM may not have the API at all, so check before using it. `supports_addon_api("1.0")` is true when the installed JCM can run an addon written for API version 1.0.

## Example

```gdscript
extends Node

const GRAVITY_ID = "jcm-moon-gravity.enabled"

var _lib = null
var _jcm = null

func _ready():
    var lib = Engine.get_meta("RTVModLib")
    if lib._is_ready:
        _on_lib_ready()
    else:
        lib.frameworks_ready.connect(_on_lib_ready)

func _on_lib_ready():
    _lib = Engine.get_meta("RTVModLib")
    _jcm = get_node_or_null("/root/jcm")
    if not _lib.has_mod("juuzoz-jcm") or not _jcm or not _jcm.has_method("supports_addon_api") or not _jcm.supports_addon_api("1.0"):
        push_warning("Moon Gravity needs JCM 3.5.0 or newer")
        return

    _jcm.register_toggle(GRAVITY_ID, "Cheats", "Moon Gravity", false, _on_gravity_toggled)
    _jcm.register_button("jcm-moon-gravity.heal", "Moon Gravity", "Full Heal", "Heal", _heal)
    _lib.hook("controller-_physics_process-post", _on_controller_process)

func _on_controller_process(_delta):
    if _jcm.is_enabled(GRAVITY_ID):
        _lib._caller.gravityMultiplier = 0.5

# Runs only when the player changes the toggle, so the vanilla value can be put back
func _on_gravity_toggled(enabled: bool):
    var controller = get_node_or_null("/root/Map/Core/Controller")
    if controller and not enabled:
        controller.gravityMultiplier = 2.0

func _heal():
    load("res://Resources/GameData.tres").health = 100.0
```

This adds a Moon Gravity toggle at the bottom of the Cheats tab, and a Moon Gravity section with a Full Heal button to the Addons tab.

## API

All methods are on the `/root/jcm` node.

| Member | Description |
|---|---|
| `ADDON_API_VERSION` | `String`. The version of this API as `"major.minor"`. Currently `"1.0"`. |
| `supports_addon_api(version) -> bool` | True if the installed JCM can run an addon written for that API version: the same major version, and at least that minor version. |
| `register_toggle(id, tab, label, default_value = false, on_toggled = Callable()) -> bool` | Adds a toggle. Returns `false` (with a warning) if the id is taken or the id, tab or label is empty. |
| `register_button(id, tab, label, button_text, on_pressed) -> bool` | Adds a row with a label and a button. `on_pressed` must be a valid `Callable`. |
| `unregister(id) -> bool` | Removes a toggle or button. A toggle's saved state is kept. |
| `is_enabled(id) -> bool` | The toggle's current state. `false` for unknown ids. |
| `set_enabled(id, enabled) -> bool` | Changes a toggle as if the player clicked it: saves it, updates the menu, runs its `on_toggled` and emits `addon_toggled`. |
| `addon_toggled(id: String, enabled: bool)` | Signal emitted when an addon toggle changes. |

### Ids

Ids are unique across all addons, so prefix them with your mod's id, like `jcm-moon-gravity.enabled`. Toggle states are saved under their id in JCM's `jcm_settings.ini`, so changing an id resets that toggle for players.

### Tabs

Use `"Cheats"`, `"Spawners"`, `"World"` or `"AI"` to add to one of JCM's tabs. Your entries go at the bottom of the tab, below a separator.

Any other name becomes a section of the Addons tab, titled with that name, so use your addon's name. The Addons tab holds every addon's sections, and only appears when at least one addon has a section. Sections and entries show in the order they're registered.

### Toggle states

- The first time a player has your addon, a toggle starts at `default_value`. After that, it starts at the player's saved state.
- `on_toggled` is only called when the state changes, not when you register. Read `is_enabled()` to get the state at startup.
- States are kept while your addon is uninstalled, so they come back if it's reinstalled.

### Timing

You can register any time, including while the menu is open; it updates right away. Registering from `_ready` or from the mod loader's `frameworks_ready`, as in the example, is the usual place.

## Changes to this API

A minor version (1.0 to 1.1) only adds to the API, so addons written for an earlier minor version keep working. A major version (1.x to 2.0) can break existing addons.

- **1.0** (JCM 3.5.0): First version. Toggles and buttons on JCM's tabs or in an addon's section of the Addons tab.
