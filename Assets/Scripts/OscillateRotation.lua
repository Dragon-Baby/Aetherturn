---@var RotationAxis          :Vector3
---@var RotationAngle         :float = 45
---@var Duration              :float = 2
---@var UseRandomDelay        :bool = false
---@var MaxRandomDelay        :float = 1
---@end

local startRotation = nil
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
    RotationAngle = ValueOrDefault(RotationAngle, 45)
    Duration = ValueOrDefault(Duration, 2)
    MaxRandomDelay = ValueOrDefault(MaxRandomDelay, 1)
    if UseRandomDelay == nil then
        UseRandomDelay = false
    end
    if startRotation == nil then
        startRotation = self.transform.rotation
    end
    if normalizedAxis == nil then
        normalizedAxis = NormalizeAxis(RotationAxis, CS.UnityEngine.Vector3.up)
    end
    if not hasInitialized then
        randomDelay = UseRandomDelay and CS.UnityEngine.Random.Range(0, MaxRandomDelay) or 0
        hasInitialized = true
    end
end

local function ApplyAngle(angle)
    self.transform.rotation = startRotation * CS.UnityEngine.Quaternion.AngleAxis(angle, normalizedAxis)
end

function Awake()
    EnsureInitialized()
end

function ResetToBase()
    EnsureInitialized()
    timeElapsed = 0
    isReversing = false
    randomDelay = UseRandomDelay and CS.UnityEngine.Random.Range(0, MaxRandomDelay) or 0
    ApplyAngle(0)
end

function Update()
    EnsureInitialized()

    if Duration <= 0 then
        ApplyAngle(isReversing and 0 or RotationAngle)
        return
    end

    local deltaTime = CS.UnityEngine.Time.deltaTime
    if timeElapsed < randomDelay then
        timeElapsed = timeElapsed + deltaTime
        return
    end

    local halfDuration = Duration / 2
    if halfDuration <= 0 then
        ApplyAngle(isReversing and 0 or RotationAngle)
        return
    end

    local progress = (timeElapsed - randomDelay) / halfDuration
    progress = math.min(math.max(progress, 0), 1)
    progress = EaseInOut(progress)

    local currentAngle = RotationAngle * (isReversing and (1 - progress) or progress)
    ApplyAngle(currentAngle)

    timeElapsed = timeElapsed + deltaTime

    if timeElapsed >= halfDuration + randomDelay then
        timeElapsed = randomDelay
        isReversing = not isReversing
    end
end
