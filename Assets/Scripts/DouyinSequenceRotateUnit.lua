---@var RotationAxis           :Vector3
---@var UseLocalSpace          :bool = true
---@var RotateAngle            :float = 90
---@var RotateSpeed            :float = 45
---@end

local currentAngle = 0
local targetAngle = 0
local rotateDirection = 1
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
    normalizedAxis = NormalizeAxis(RotationAxis, CS.UnityEngine.Vector3.up)
end

local function EnsureInitialized()
    if UseLocalSpace == nil then
        UseLocalSpace = true
    end
    RotateAngle = ClampNonNegative(RotateAngle, 90)
    RotateSpeed = ClampNonNegative(RotateSpeed, 45)
    if normalizedAxis == nil then
        RefreshAxis()
    end
    hasInitialized = true
end

local function GetSpace()
    return UseLocalSpace and CS.UnityEngine.Space.Self or CS.UnityEngine.Space.World
end

local function ApplyAbsoluteAngle(nextAngle)
    local deltaAngle = nextAngle - currentAngle
    if math.abs(deltaAngle) > 0.0001 then
        self.transform:Rotate(normalizedAxis, deltaAngle, GetSpace())
    end
    currentAngle = nextAngle
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
    ApplyAbsoluteAngle(0)
    targetAngle = 0
    rotateDirection = 1
    isPlaying = false
    isComplete = true
end

function BeginForward()
    EnsureInitialized()
    targetAngle = RotateAngle
    rotateDirection = 1
    isComplete = false

    if RotateAngle <= 0 or RotateSpeed <= 0 then
        ApplyAbsoluteAngle(RotateAngle)
        isPlaying = false
        isComplete = true
        return
    end

    isPlaying = true
end

function BeginBackward()
    EnsureInitialized()
    targetAngle = 0
    rotateDirection = -1
    isComplete = false

    if RotateAngle <= 0 or RotateSpeed <= 0 then
        ApplyAbsoluteAngle(0)
        isPlaying = false
        isComplete = true
        return
    end

    isPlaying = true
end

function Tick(deltaTime)
    EnsureInitialized()
    if not isPlaying or isComplete then
        return
    end

    local nextAngle = currentAngle + rotateDirection * RotateSpeed * deltaTime

    if rotateDirection > 0 and nextAngle >= targetAngle then
        ApplyAbsoluteAngle(targetAngle)
        isPlaying = false
        isComplete = true
        return
    end

    if rotateDirection < 0 and nextAngle <= targetAngle then
        ApplyAbsoluteAngle(targetAngle)
        isPlaying = false
        isComplete = true
        return
    end

    ApplyAbsoluteAngle(nextAngle)
end

function IsComplete()
    return isComplete
end

function GetProgress01()
    if RotateAngle <= 0 then
        return 1
    end
    return math.min(math.max(currentAngle / RotateAngle, 0), 1)
end
