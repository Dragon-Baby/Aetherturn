---@var PendulumGroup          :DouyinScript
---@var ExtendGroup            :DouyinScript
---@var BallGroup              :DouyinScript
---@var OrbitGroup             :DouyinScript
---@var GearGroup              :DouyinScript
---@var FxBridge               :DouyinScript
---@var VertexLightManager     :DouyinScript
---@var EnableValidationLog    :bool = true
---@end

local function Log(message)
    if EnableValidationLog then
        print("[DouyinSequenceRegistry] " .. tostring(message))
    end
end

local function CallScript(target, funcName, ...)
    if target == nil or target.script == nil then
        return nil
    end

    local fn = target.script[funcName]
    if fn == nil then
        return nil
    end

    return fn(...)
end

local function ValidateScript(target, label)
    if target == nil then
        Log(label .. " is nil")
        return false
    end
    if target.script == nil then
        Log(label .. ".script is nil")
        return false
    end
    return true
end

function Validate()
    local ok = true
    ok = ValidateScript(PendulumGroup, "PendulumGroup") and ok
    ok = ValidateScript(ExtendGroup, "ExtendGroup") and ok
    ok = ValidateScript(BallGroup, "BallGroup") and ok
    ok = ValidateScript(OrbitGroup, "OrbitGroup") and ok
    ok = ValidateScript(GearGroup, "GearGroup") and ok
    if FxBridge ~= nil then
        ok = ValidateScript(FxBridge, "FxBridge") and ok
    end
    if VertexLightManager ~= nil then
        ok = ValidateScript(VertexLightManager, "VertexLightManager") and ok
    end
    return ok
end

function CollectAll()
    CallScript(PendulumGroup, "CollectUnits")
    CallScript(ExtendGroup, "CollectUnits")
    CallScript(BallGroup, "CollectUnits")
    CallScript(OrbitGroup, "CollectUnits")
    CallScript(GearGroup, "CollectUnits")
    CallScript(VertexLightManager, "CollectLights")
end

function ResetAllToBase()
    CallScript(PendulumGroup, "ResetToBase")
    CallScript(ExtendGroup, "ResetToBase")
    CallScript(BallGroup, "ResetToBase")
    CallScript(OrbitGroup, "ResetToBase")
    CallScript(GearGroup, "ResetToBase")
    CallScript(FxBridge, "ResetToBase")
    CallScript(VertexLightManager, "ResetToBase")
end

function BeginPendulums()
    CallScript(PendulumGroup, "BeginForward")
end

function TickPendulums(deltaTime)
    CallScript(PendulumGroup, "Tick", deltaTime)
end

function ArePendulumsComplete()
    return CallScript(PendulumGroup, "IsComplete") == true
end

function BeginExtendForward()
    CallScript(ExtendGroup, "BeginForward")
end

function BeginExtendBackward()
    CallScript(ExtendGroup, "BeginBackward")
end

function TickExtenders(deltaTime)
    CallScript(ExtendGroup, "Tick", deltaTime)
end

function AreExtendersComplete()
    return CallScript(ExtendGroup, "IsComplete") == true
end

function BeginBallForward()
    CallScript(BallGroup, "BeginForward")
end

function BeginBallBackward()
    CallScript(BallGroup, "BeginBackward")
end

function TickBalls(deltaTime)
    CallScript(BallGroup, "Tick", deltaTime)
end

function AreBallsComplete()
    return CallScript(BallGroup, "IsComplete") == true
end

function BeginOrbit()
    CallScript(OrbitGroup, "BeginForward")
end

function TickOrbit(deltaTime)
    CallScript(OrbitGroup, "Tick", deltaTime)
end

function IsOrbitComplete()
    return CallScript(OrbitGroup, "IsComplete") == true
end

function GetOrbitSpeedFactor()
    local speedFactor = CallScript(OrbitGroup, "GetSpeedFactor")
    if speedFactor == nil then
        return 0
    end
    return speedFactor
end

function GetOrbitProgress01()
    local progress = CallScript(OrbitGroup, "GetProgress01")
    if progress == nil then
        return 0
    end
    return progress
end

function GetOrbitDuration()
    local duration = CallScript(OrbitGroup, "GetTotalDuration")
    if duration == nil then
        return 0
    end
    return duration
end

function TickGears(deltaTime, driveFactor)
    CallScript(GearGroup, "Tick", deltaTime, driveFactor)
end

function BeginOrbitFx(totalDuration)
    CallScript(FxBridge, "BeginOrbitFx", totalDuration)
end

function TickOrbitFx(deltaTime, progress01)
    CallScript(FxBridge, "TickOrbitFx", deltaTime, progress01)
end

function CompleteOrbitFx()
    CallScript(FxBridge, "CompleteOrbitFx")
end

function GetOrbitNightBlend01(progress01)
    local blend = CallScript(FxBridge, "GetOrbitNightBlend01", progress01)
    if blend == nil then
        return 0
    end
    return blend
end

function GetCurrentNightBlend01()
    local blend = CallScript(FxBridge, "GetCurrentNightBlend01")
    if blend == nil then
        return 0
    end
    return blend
end

function TickVertexLights(deltaTime)
    CallScript(VertexLightManager, "Tick", deltaTime)
end

function ApplyVertexLights()
    CallScript(VertexLightManager, "ApplyGlobals")
end

function SetVertexLightIntensity(lightIndex, intensity)
    CallScript(VertexLightManager, "SetLightIntensity", lightIndex, intensity)
end

function SetVertexLightIntensityScale(lightIndex, scale)
    CallScript(VertexLightManager, "SetLightIntensityScale", lightIndex, scale)
end

function FadeVertexLightIntensity(lightIndex, targetIntensity, duration)
    CallScript(VertexLightManager, "FadeLightIntensity", lightIndex, targetIntensity, duration)
end

function FadeVertexLightIntensityScale(lightIndex, targetScale, duration)
    CallScript(VertexLightManager, "FadeLightIntensityScale", lightIndex, targetScale, duration)
end

function SetAllVertexLightIntensityScale(scale)
    CallScript(VertexLightManager, "SetAllIntensityScale", scale)
end

function FadeAllVertexLightIntensityScale(targetScale, duration)
    CallScript(VertexLightManager, "FadeAllIntensityScale", targetScale, duration)
end
