---@var RotationAxis    :Vector3
---@var UseLocalSpace   :bool = true
---@var SlowSpeed       :float = 30
---@var FastSpeed       :float = 180
---@var StartBlend      :float = 0
---@var SmoothFactor    :float = 8
---@end

local currentSpeed = 0
local targetSpeed = 0
local rotationAxis = nil
local rotationSpace = nil

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

local function GetSpeedByBlend(blend)
    return CS.UnityEngine.Mathf.Lerp(SlowSpeed, FastSpeed, Clamp01(blend))
end

local function RefreshAxisAndSpace()
    if RotationAxis == nil or RotationAxis.sqrMagnitude <= 0.0001 then
        RotationAxis = CS.UnityEngine.Vector3.up
    end

    rotationAxis = RotationAxis.normalized
    rotationSpace = UseLocalSpace and CS.UnityEngine.Space.Self or CS.UnityEngine.Space.World
end

function Awake()
    if SlowSpeed == nil then
        SlowSpeed = 30
    end
    if FastSpeed == nil then
        FastSpeed = 180
    end
    if StartBlend == nil then
        StartBlend = 0
    end
    if SmoothFactor == nil or SmoothFactor <= 0 then
        SmoothFactor = 8
    end

    RefreshAxisAndSpace()

    currentSpeed = GetSpeedByBlend(StartBlend)
    targetSpeed = currentSpeed
end

function Update()
    local deltaTime = CS.UnityEngine.Time.deltaTime
    local lerpT = 1 - math.exp(-SmoothFactor * deltaTime)

    currentSpeed = CS.UnityEngine.Mathf.Lerp(currentSpeed, targetSpeed, lerpT)
    self.transform:Rotate(rotationAxis, currentSpeed * deltaTime, rotationSpace)
end

function UseSlowSpeed()
    targetSpeed = SlowSpeed
end

function UseFastSpeed()
    targetSpeed = FastSpeed
end

function SetUseFast(useFast)
    if useFast then
        UseFastSpeed()
    else
        UseSlowSpeed()
    end
end

function SetSpeedBlend(blend)
    targetSpeed = GetSpeedByBlend(blend)
end

function SetSpeed(speed)
    if speed == nil then
        return
    end
    targetSpeed = CS.UnityEngine.Mathf.Max(0, speed)
end

function SetRotationAxis(axis)
    RotationAxis = axis
    RefreshAxisAndSpace()
end

function SetUseLocalSpace(useLocal)
    UseLocalSpace = useLocal
    RefreshAxisAndSpace()
end

function GetCurrentSpeed()
    return currentSpeed
end
