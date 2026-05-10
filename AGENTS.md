# Aetherturn Agent Notes

These notes capture project-specific conventions for future Codex sessions. Read this file before editing Lua scripts, shader globals, or environment preview tooling.

## Important Paths

- Runtime Lua bridge for the sequence/environment effect:
  - `Assets/Scripts/DouyinSequenceFxBridge.lua`
- Editor/runtime C# preview helper for global shader properties only:
  - `Assets/Scripts/DouyinEnvironmentPreviewGlobals.cs`
- Main scene with `DouyinSceneEnvironment` serialized settings:
  - `Assets/Scenes/Aetherturn.unity`
- Custom lit shader graph using ambient color properties:
  - `Assets/Art/Shaders/SG_Lit.shadergraph`
- Example material containing `_SkyColor`, `_EquatorColor`, `_GroundColor`:
  - `Assets/Art/Env/Mat/M_Ground.mat`
- Douyin scene environment example assets:
  - `Assets/DouyinVCreateSDK/World/Examples/DouyinSceneEnvironment/`

## Lua Script Notes

- Douyin Lua exposed variables are declared at the top of scripts with `---@var ...` and closed with `---@end`.
- Douyin Lua inspector supports array types.
  - Examples:
    - `---@var intValues:int[]`
    - `---@var stringValues:string[]`
    - `---@var gameObjects:UnityEngine.GameObject[]`
- For group-style controllers, prefer binding `UnityEngine.GameObject[]` plus a script name over hardcoding many single slots or walking child hierarchies.
  - Current sequence groups follow this pattern:
    - `UnitObjects : UnityEngine.GameObject[]`
    - `UnitScriptName : string`
- To call another Douyin Lua script through an exposed script reference, declare it as `DouyinScript` and call through `.script`.
  - Example:
    - `---@var myScript:DouyinScript`
    - `myScript.script.Func()`
  - Do not use `myScript:Func()`.
- To fetch another Douyin Lua script from a bound object, call `GetDouyinScript("ScriptName")` on the owning object, then use `.script`.
  - Example:
    - `local bScript = someGameObject:GetDouyinScript("A")`
    - `if bScript ~= nil then`
    - `    bScript.script.Func()`
    - `end`
- If one object may carry multiple scripts of the same name, use `GetDouyinScripts("ScriptName")` instead of `GetDouyinScript("ScriptName")`.
- `GetDouyinScript` / `GetDouyinScripts` are object-level lookup APIs. Prefer binding the target `GameObject` first, then resolving the Lua script by name from that object.
- For color variables exposed to the Douyin Lua inspector, use `Color`, not `UnityEngine.Color`.
  - Example:
    - `---@var DaySkyColor :Color`
    - `---@var NightSkyColor :Color`
- When passing exposed `Color` values into Unity APIs, convert to `CS.UnityEngine.Color` first.
  - Current reference implementation:
    - `Assets/Scripts/DouyinSequenceFxBridge.lua`
    - `ToUnityColor(value)` converts `value.r`, `value.g`, `value.b`, `value.a`.
- Lua scripts only take effect after Douyin compile/runtime flow. They are not reliable for normal Unity editor preview.
- Do not assume `Awake()` execution order between controller scripts and child/unit scripts.
  - A controller may call into other Douyin Lua scripts before those scripts run their own `Awake()`.
  - Unit-style scripts should be safe when called before `Awake()` completes.
  - Prefer lazy initialization helpers such as `EnsureInitialized()` inside `ResetToBase()`, `BeginForward()`, `BeginBackward()`, and `Tick()`.
- Be careful not to reset runtime state twice during startup.
  - A common bug pattern is:
    - controller `Awake()` starts a sequence
    - unit script begins playing
    - unit script's own `Awake()` runs afterward and calls `ResetToBase()`
    - first loop appears broken, later loops appear normal
  - Guard against this by making unit `Awake()` idempotent and skipping startup reset if the unit was already initialized externally.
- Use `CS.UnityEngine.Shader.SetGlobalColor` / `SetGlobalFloat` for shader globals from Lua.
- Use `pcall` around access to SDK objects such as `SceneEnvironment.settings` so missing or changed SDK members do not hard-crash the script.
- For vector axes, do not rely on another script having already initialized cached normalized vectors.
  - Either recompute on demand or ensure the cache is initialized lazily before use.
  - In this project, sequence unit scripts use local `NormalizeAxis(...)` helpers rather than assuming `.normalized` was already cached during `Awake()`.

## Environment Blend Logic

- The sky transition is driven by the active sky material properties:
  - `_ReverseBlend`
  - `_PulseProgress`
- The shared day/night blend is:
  - `pulseProgress` when `_ReverseBlend <= 0.5`
  - `1 - pulseProgress` when `_ReverseBlend > 0.5`
- Treat the result as `nightBlend01`.
  - Day to night: `0 -> 1`
  - Night to day: `1 -> 0`
- Keep all related values on the same `nightBlend01` so the sky, ambient colors, emission, and main light stay in phase.

## Shader Global Properties

The current project convention is to set these globals during the day/night transition:

- `_SkyColor`
- `_EquatorColor`
- `_GroundColor`
- `_EmissionIntensity`

Expected defaults:

- `_EmissionIntensity`
  - Day: `0`
  - Night: `1`
- Ambient colors:
  - Configurable day and night color sets.
  - Lerp day to night using `nightBlend01`.

For editor preview, only set global shader properties. Do not write `RenderSettings`, material-local properties, or Douyin scene environment settings unless the user explicitly asks.

## C# Preview Notes

- Use `Assets/Scripts/DouyinEnvironmentPreviewGlobals.cs` for Unity editor preview.
- The preview component is `[ExecuteAlways]`.
- It should only call:
  - `Shader.SetGlobalColor("_SkyColor", ...)`
  - `Shader.SetGlobalColor("_EquatorColor", ...)`
  - `Shader.SetGlobalColor("_GroundColor", ...)`
  - `Shader.SetGlobalFloat("_EmissionIntensity", ...)`
- It can either:
  - Read `_ReverseBlend` / `_PulseProgress` from a configured `skyMaterial`, or
  - Use the manual `nightBlend01` slider when `readBlendFromSkyMaterial` is disabled.

## Main Light Notes

- Runtime Lua bridge may write `SceneEnvironment.settings.mainLightStrength`.
- The requested behavior is:
  - Day: max value, usually `DayMainLightStrength = 1`
  - Night: min value, usually `NightMainLightStrength = 0`
  - Lerp using the same `nightBlend01`.
- Do not include main light editing in the C# preview helper unless explicitly requested; preview helper is currently shader globals only.

## Search and Tooling Notes

- Prefer `rg` when available, but in this environment `rg.exe` may be blocked with access denied.
- Fallback PowerShell search commands that worked:
  - `Get-ChildItem -Path .\Assets -Recurse -Include *.lua,*.cs | Select-String -Pattern '...'`
  - `Get-ChildItem -Path .\Assets -Recurse -Include *.shader,*.shadergraph,*.mat | Select-String -Pattern '...'`
- This workspace may appear through a sandboxed path in command output even when the requested cwd is `D:\Unity\Aetherturn`; still use `D:\Unity\Aetherturn` for user-facing file links.
