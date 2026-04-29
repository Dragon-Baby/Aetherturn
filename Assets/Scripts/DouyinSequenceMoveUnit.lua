---@var MoveAxis               :Vector3
---@var UseLocalSpace          :bool = true
---@var MoveDistance           :float = 1
---@var MoveSpeed              :float = 0.5
---@end

local baseLocalPosition = nil
local baseWorldPosition = nil
local currentDistance = 0
local targetDistance = 0
local moveDirection = 1
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
    normalizedAxis = NormalizeAxis(MoveAxis, CS.UnityEngine.Vector3.right)
end

local function EnsureInitialized()
    if UseLocalSpace == nil then
        UseLocalSpace = true
    end
    MoveDistance = ClampNonNegative(MoveDistance, 1)
    MoveSpeed = ClampNonNegative(MoveSpeed, 0.5)
    if normalizedAxis == nil then
        RefreshAxis()
    end
    if baseLocalPosition == nil then
        baseLocalPosition = self.transform.localPosition
    end
    if baseWorldPosition == nil then
        baseWorldPosition = self.transform.position
    end
    hasInitialized = true
end

local function BuildOffset(distance)
    return CS.UnityEngine.Vector3(
        normalizedAxis.x * distance,
        normalizedAxis.y * distance,
        normalizedAxis.z * distance
    )
end

local function ApplyCurrentDistance()
    local offset = BuildOffset(currentDistance)
    if UseLocalSpace then
        self.transform.localPosition = CS.UnityEngine.Vector3(
            baseLocalPosition.x + offset.x,
            baseLocalPosition.y + offset.y,
            baseLocalPosition.z + offset.z
        )
    else
        self.transform.position = CS.UnityEngine.Vector3(
            baseWorldPosition.x + offset.x,
            baseWorldPosition.y + offset.y,
            baseWorldPosition.z + offset.z
        )
    end
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
    currentDistance = 0
    targetDistance = 0
    moveDirection = 1
    isPlaying = false
    isComplete = true
    ApplyCurrentDistance()
end

function BeginForward()
    EnsureInitialized()
    targetDistance = MoveDistance
    moveDirection = 1
    isComplete = false

    if MoveDistance <= 0 or MoveSpeed <= 0 then
        currentDistance = MoveDistance
        ApplyCurrentDistance()
        isPlaying = false
        isComplete = true
        return
    end

    isPlaying = true
end

function BeginBackward()
    EnsureInitialized()
    targetDistance = 0
    moveDirection = -1
    isComplete = false

    if MoveDistance <= 0 or MoveSpeed <= 0 then
        currentDistance = 0
        ApplyCurrentDistance()
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

    currentDistance = currentDistance + moveDirection * MoveSpeed * deltaTime

    if moveDirection > 0 and currentDistance >= targetDistance then
        currentDistance = targetDistance
        ApplyCurrentDistance()
        isPlaying = false
        isComplete = true
        return
    end

    if moveDirection < 0 and currentDistance <= targetDistance then
        currentDistance = targetDistance
        ApplyCurrentDistance()
        isPlaying = false
        isComplete = true
        return
    end

    ApplyCurrentDistance()
end

function IsComplete()
    return isComplete
end

function GetProgress01()
    if MoveDistance <= 0 then
        return 1
    end
    return math.min(math.max(currentDistance / MoveDistance, 0), 1)
end
