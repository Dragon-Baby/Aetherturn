---@var Radius                 :float = 4
---@var Color                  :Color
---@var Intensity              :float = 1
---@var InitialIntensity       :float = 1
---@var Manager                :DouyinScript
---@var AutoRegister           :bool = true
---@var DisableUnityLight      :bool = true
---@var EnableDebugLog         :bool = false
---@end

local baseIntensity = 1
local currentIntensity = 1
local fadeStartIntensity = 1
local fadeTargetIntensity = 1
local fadeDuration = 0
local fadeElapsed = 0
local isFading = false
local hasInitialized = false

local function Log(message)
    if EnableDebugLog then
        print("[DouyinVertexLightUnit] " .. tostring(message))
    end
end

local function ClampNonNegative(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    if value < 0 then
        return 0
    end
    return value
end

local function Clamp01(value)
    if value == nil then
        return 0
    end
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function ResolveColor()
    if Color == nil then
        return CS.UnityEngine.Color.white
    end
    return Color
end

local function ApplyUnityLightState()
    if not DisableUnityLight then
        return
    end

    local light = self.gameObject:GetComponent(typeof(CS.UnityEngine.Light))
    if light ~= nil then
        light.enabled = false
    end
end

local function EnsureInitialized()
    Radius = ClampNonNegative(Radius, 4)
    Intensity = ClampNonNegative(Intensity, 1)
    if InitialIntensity == nil then
        InitialIntensity = Intensity
    end
    InitialIntensity = ClampNonNegative(InitialIntensity, Intensity)
    if DisableUnityLight == nil then
        DisableUnityLight = true
    end
    if AutoRegister == nil then
        AutoRegister = true
    end
    if EnableDebugLog == nil then
        EnableDebugLog = false
    end

    if not hasInitialized then
        baseIntensity = InitialIntensity
        currentIntensity = InitialIntensity
        Intensity = currentIntensity
    end

    ApplyUnityLightState()
    hasInitialized = true
end

function Awake()
    EnsureInitialized()
    if AutoRegister and Manager ~= nil and Manager.script ~= nil then
        Manager.script.RegisterLight(self)
    end
end

function ResetToBase()
    EnsureInitialized()
    currentIntensity = baseIntensity
    Intensity = currentIntensity
    isFading = false
    fadeElapsed = 0
end

function Tick(deltaTime)
    EnsureInitialized()
    ApplyUnityLightState()

    if not isFading then
        currentIntensity = ClampNonNegative(Intensity, currentIntensity)
        return
    end

    if fadeDuration <= 0 then
        currentIntensity = fadeTargetIntensity
        Intensity = currentIntensity
        isFading = false
        return
    end

    fadeElapsed = fadeElapsed + deltaTime
    local t = Clamp01(fadeElapsed / fadeDuration)
    currentIntensity = fadeStartIntensity + (fadeTargetIntensity - fadeStartIntensity) * t
    Intensity = currentIntensity

    if t >= 1 then
        isFading = false
    end
end

function SetIntensity(value)
    EnsureInitialized()
    currentIntensity = ClampNonNegative(value, 0)
    Intensity = currentIntensity
    isFading = false
end

function SetIntensityScale(scale)
    EnsureInitialized()
    SetIntensity(baseIntensity * ClampNonNegative(scale, 0))
end

function FadeIntensity(targetIntensity, duration)
    EnsureInitialized()
    fadeStartIntensity = currentIntensity
    fadeTargetIntensity = ClampNonNegative(targetIntensity, 0)
    fadeDuration = ClampNonNegative(duration, 0)
    fadeElapsed = 0
    isFading = true

    if fadeDuration <= 0 then
        SetIntensity(fadeTargetIntensity)
    end
end

function FadeIntensityScale(targetScale, duration)
    EnsureInitialized()
    FadeIntensity(baseIntensity * ClampNonNegative(targetScale, 0), duration)
end

function SetRadius(value)
    EnsureInitialized()
    Radius = ClampNonNegative(value, Radius)
end

function SetColor(value)
    if value ~= nil then
        Color = value
    end
end

function GetPosition()
    return self.transform.position
end

function GetRadius()
    EnsureInitialized()
    return Radius
end

function GetColor()
    return ResolveColor()
end

function GetIntensity()
    EnsureInitialized()
    return currentIntensity
end

function IsActive()
    EnsureInitialized()
    return Radius > 0 and currentIntensity > 0
end

function IsFading()
    return isFading
end
