---@var RotationAxis    :Vector3
---@var UseLocalSpace   :bool = true
---@var MaxAngle        :float = 30
---@var SlowSpeed       :float = 1.5
---@var FastSpeed       :float = 3.0
---@var StartBlend      :float = 0
---@var StartPhase      :float = 0
---@var SmoothFactor    :float = 8
---@end

local currentSpeed = 0
local targetSpeed = 0
local rotationAxis = nil
local phase = 0
local lastAppliedAngle = 0

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

local function RefreshAxis()
    if RotationAxis == nil or RotationAxis.sqrMagnitude <= 0.0001 then
        RotationAxis = CS.UnityEngine.Vector3.forward
    end

    rotationAxis = RotationAxis.normalized
end

local function ApplyAngleImmediate(targetAngle)
    local deltaAngle = targetAngle - lastAppliedAngle
    local rotationSpace = UseLocalSpace and CS.UnityEngine.Space.Self or CS.UnityEngine.Space.World

    self.transform:Rotate(rotationAxis, deltaAngle, rotationSpace)
    lastAppliedAngle = targetAngle
end

function Awake()
    if SlowSpeed == nil then
        SlowSpeed = 1.5
    end
    if FastSpeed == nil then
        FastSpeed = 3.0
    end
    if MaxAngle == nil then
        MaxAngle = 30
    end
    if StartBlend == nil then
        StartBlend = 0
    end
    if StartPhase == nil then
        StartPhase = 0
    end
    if SmoothFactor == nil or SmoothFactor <= 0 then
        SmoothFactor = 8
    end

    RefreshAxis()

    currentSpeed = GetSpeedByBlend(StartBlend)
    targetSpeed = currentSpeed
    phase = StartPhase
    lastAppliedAngle = 0

    ApplyAngleImmediate(math.sin(phase) * MaxAngle)
end

function Update()
    local deltaTime = CS.UnityEngine.Time.deltaTime
    local lerpT = 1 - math.exp(-SmoothFactor * deltaTime)

    currentSpeed = CS.UnityEngine.Mathf.Lerp(currentSpeed, targetSpeed, lerpT)
    phase = phase + currentSpeed * deltaTime

    ApplyAngleImmediate(math.sin(phase) * MaxAngle)
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

function SetMaxAngle(angle)
    if angle == nil then
        return
    end
    MaxAngle = CS.UnityEngine.Mathf.Max(0, angle)
end

function SetMaxHeight(angle)
    SetMaxAngle(angle)
end

function SetRotationAxis(axis)
    RotationAxis = axis
    RefreshAxis()
end

function SetUseLocalSpace(useLocal)
    UseLocalSpace = useLocal
end

function SetCenterAsCurrentRotation()
    lastAppliedAngle = 0
    phase = 0
end

function GetCurrentSpeed()
    return currentSpeed
end
