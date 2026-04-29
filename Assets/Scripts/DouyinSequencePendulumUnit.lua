---@var RotationAxis           :Vector3
---@var UseLocalSpace          :bool = true
---@var MaxAngle               :float = 20
---@var Speed                  :float = 2
---@var StartPhase             :float = 0
---@var StopAngle              :float = 0
---@end

local TWO_PI = math.pi * 2

local baseLocalRotation = nil
local baseWorldRotation = nil
local currentPhase = 0
local lastAppliedAngle = 0
local requiredSwingCount = 1
local completedCycles = 0
local isPlaying = false
local isComplete = true
local normalizedAxis = nil
local hasInitialized = false

local function ClampNonNegative(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    if value < 0 then
        return 0
    end
    return value
end

local function NormalizeAxis(axis, fallbackAxis)
    local source = axis
    if source == nil or source.sqrMagnitude <= 0.0001 then
        source = fallbackAxis
    end

    local magnitude = math.sqrt(source.x * source.x + source.y * source.y + source.z * source.z)
    if magnitude <= 0.0001 then
        return fallbackAxis
    end

    return CS.UnityEngine.Vector3(source.x / magnitude, source.y / magnitude, source.z / magnitude)
end

local function RefreshAxis()
    normalizedAxis = NormalizeAxis(RotationAxis, CS.UnityEngine.Vector3.forward)
end

local function EnsureInitialized()
    if UseLocalSpace == nil then
        UseLocalSpace = true
    end
    MaxAngle = ClampNonNegative(MaxAngle, 20)
    Speed = ClampNonNegative(Speed, 2)
    if StartPhase == nil then
        StartPhase = 0
    end
    if StopAngle == nil then
        StopAngle = 0
    end
    if normalizedAxis == nil then
        RefreshAxis()
    end
    if baseLocalRotation == nil then
        baseLocalRotation = self.transform.localRotation
    end
    if baseWorldRotation == nil then
        baseWorldRotation = self.transform.rotation
    end
    hasInitialized = true
end

local function GetSpace()
    return UseLocalSpace and CS.UnityEngine.Space.Self or CS.UnityEngine.Space.World
end

local function ApplyDeltaAngle(deltaAngle)
    if math.abs(deltaAngle) <= 0.0001 then
        return
    end
    self.transform:Rotate(normalizedAxis, deltaAngle, GetSpace())
end

local function ApplyAbsoluteAngle(targetAngle)
    local deltaAngle = targetAngle - lastAppliedAngle
    ApplyDeltaAngle(deltaAngle)
    lastAppliedAngle = targetAngle
end

function Awake()
    local alreadyInitialized = hasInitialized
    EnsureInitialized()
    if not alreadyInitialized then
        ResetToBase()
    end
end

function ResetToBase()
    EnsureInitialized()

    if UseLocalSpace then
        self.transform.localRotation = baseLocalRotation
    else
        self.transform.rotation = baseWorldRotation
    end

    currentPhase = StartPhase
    lastAppliedAngle = 0
    completedCycles = 0
    requiredSwingCount = 1
    isPlaying = false
    isComplete = true

    ApplyAbsoluteAngle(math.sin(currentPhase) * MaxAngle)
end

function BeginForward(swingCount)
    EnsureInitialized()
    ResetToBase()
    requiredSwingCount = swingCount ~= nil and math.max(0, swingCount) or 1

    if requiredSwingCount <= 0 or MaxAngle <= 0 or Speed <= 0 then
        ApplyAbsoluteAngle(StopAngle)
        isPlaying = false
        isComplete = true
        return
    end

    isPlaying = true
    isComplete = false
end

function BeginBackward()
    BeginForward(requiredSwingCount)
end

function Tick(deltaTime)
    EnsureInitialized()
    if not isPlaying or isComplete then
        return
    end

    local previousPhase = currentPhase
    currentPhase = currentPhase + Speed * deltaTime

    local previousCycles = math.floor((previousPhase - StartPhase) / TWO_PI)
    local currentCyclesCount = math.floor((currentPhase - StartPhase) / TWO_PI)
    if currentCyclesCount > previousCycles then
        completedCycles = currentCyclesCount
    end

    ApplyAbsoluteAngle(math.sin(currentPhase) * MaxAngle)

    if completedCycles >= requiredSwingCount then
        ApplyAbsoluteAngle(StopAngle)
        isPlaying = false
        isComplete = true
    end
end

function IsComplete()
    return isComplete
end

function GetProgress01()
    if requiredSwingCount <= 0 then
        return 1
    end
    return math.min(completedCycles / requiredSwingCount, 1)
end
