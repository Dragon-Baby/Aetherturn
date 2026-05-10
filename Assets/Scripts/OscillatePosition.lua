---@var MoveAxis              :Vector3
---@var MoveDistance          :float = 2
---@var Duration              :float = 2
---@var UseRandomDelay        :bool = false
---@var MaxRandomDelay        :float = 1
---@end

local startPosition = nil
local timeElapsed = 0
local isReversing = false
local randomDelay = 0
local normalizedAxis = nil
local hasInitialized = false

local function ValueOrDefault(value, defaultValue)
    if value == nil then
        return defaultValue
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

local function EaseInOut(t)
    if t < 0.5 then
        return 4 * t * t * t
    end
    local inverse = -2 * t + 2
    return 1 - inverse * inverse * inverse / 2
end

local function EnsureInitialized()
    MoveDistance = ValueOrDefault(MoveDistance, 2)
    Duration = ValueOrDefault(Duration, 2)
    MaxRandomDelay = ValueOrDefault(MaxRandomDelay, 1)
    if UseRandomDelay == nil then
        UseRandomDelay = false
    end
    if startPosition == nil then
        startPosition = self.transform.position
    end
    if normalizedAxis == nil then
        normalizedAxis = NormalizeAxis(MoveAxis, CS.UnityEngine.Vector3.up)
    end
    if not hasInitialized then
        randomDelay = UseRandomDelay and CS.UnityEngine.Random.Range(0, MaxRandomDelay) or 0
        hasInitialized = true
    end
end

local function ApplyDistance(distance)
    self.transform.position = CS.UnityEngine.Vector3(
        startPosition.x + normalizedAxis.x * distance,
        startPosition.y + normalizedAxis.y * distance,
        startPosition.z + normalizedAxis.z * distance
    )
end

function Awake()
    EnsureInitialized()
end

function ResetToBase()
    EnsureInitialized()
    timeElapsed = 0
    isReversing = false
    randomDelay = UseRandomDelay and CS.UnityEngine.Random.Range(0, MaxRandomDelay) or 0
    ApplyDistance(0)
end

function Update()
    EnsureInitialized()

    if Duration <= 0 then
        ApplyDistance(isReversing and 0 or MoveDistance)
        return
    end

    local deltaTime = CS.UnityEngine.Time.deltaTime
    if timeElapsed < randomDelay then
        timeElapsed = timeElapsed + deltaTime
        return
    end

    local halfDuration = Duration / 2
    if halfDuration <= 0 then
        ApplyDistance(isReversing and 0 or MoveDistance)
        return
    end

    local progress = (timeElapsed - randomDelay) / halfDuration
    progress = math.min(math.max(progress, 0), 1)
    progress = EaseInOut(progress)

    local currentDistance = MoveDistance * (isReversing and (1 - progress) or progress)
    ApplyDistance(currentDistance)

    timeElapsed = timeElapsed + deltaTime

    if timeElapsed >= halfDuration + randomDelay then
        timeElapsed = randomDelay
        isReversing = not isReversing
    end
end
