---@var OrbitCenter            :UnityEngine.Transform
---@var OrbitAxis              :Vector3
---@var OrbitLoops             :float = 2
---@var AccelDuration          :float = 1
---@var CruiseDuration         :float = 1
---@var DecelDuration          :float = 1
---@var KeepOriginalRotation   :bool = false
---@end

local baseWorldPosition = nil
local baseWorldRotation = nil
local cachedCenterPosition = nil
local currentAngle = 0
local elapsedTime = 0
local totalAngle = 0
local totalDuration = 0
local maxAngularSpeed = 0
local accelRate = 0
local decelRate = 0
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
    normalizedAxis = NormalizeAxis(OrbitAxis, CS.UnityEngine.Vector3.up)
end

local function RebuildMotionProfile()
    OrbitLoops = ClampNonNegative(OrbitLoops, 2)
    AccelDuration = ClampNonNegative(AccelDuration, 1)
    CruiseDuration = ClampNonNegative(CruiseDuration, 1)
    DecelDuration = ClampNonNegative(DecelDuration, 1)

    totalAngle = 360 * OrbitLoops
    totalDuration = AccelDuration + CruiseDuration + DecelDuration

    local effectiveTime = 0.5 * AccelDuration + CruiseDuration + 0.5 * DecelDuration
    if effectiveTime <= 0.0001 or totalAngle <= 0.0001 then
        maxAngularSpeed = 0
        accelRate = 0
        decelRate = 0
        return
    end

    maxAngularSpeed = totalAngle / effectiveTime
    accelRate = AccelDuration > 0 and (maxAngularSpeed / AccelDuration) or 0
    decelRate = DecelDuration > 0 and (maxAngularSpeed / DecelDuration) or 0
end

local function EnsureInitialized()
    if KeepOriginalRotation == nil then
        KeepOriginalRotation = false
    end
    if normalizedAxis == nil then
        RefreshAxis()
    end
    RebuildMotionProfile()
    if baseWorldPosition == nil then
        baseWorldPosition = self.transform.position
    end
    if baseWorldRotation == nil then
        baseWorldRotation = self.transform.rotation
    end
    hasInitialized = true
end

local function CaptureBaseState()
    baseWorldPosition = self.transform.position
    baseWorldRotation = self.transform.rotation
end

local function ResolveCenterPosition()
    if OrbitCenter ~= nil then
        return OrbitCenter.position
    end
    return baseWorldPosition
end

local function GetAngleAtTime(time)
    if time <= 0 then
        return 0
    end

    if totalDuration <= 0.0001 or totalAngle <= 0.0001 then
        return totalAngle
    end

    local angle = 0
    local t = time

    if AccelDuration > 0 then
        if t < AccelDuration then
            return 0.5 * accelRate * t * t
        end
        angle = angle + 0.5 * maxAngularSpeed * AccelDuration
        t = t - AccelDuration
    end

    if CruiseDuration > 0 then
        if t < CruiseDuration then
            return angle + maxAngularSpeed * t
        end
        angle = angle + maxAngularSpeed * CruiseDuration
        t = t - CruiseDuration
    end

    if DecelDuration > 0 and t < DecelDuration then
        return angle + maxAngularSpeed * t - 0.5 * decelRate * t * t
    end

    return totalAngle
end

local function ApplyAngle(targetAngle)
    local deltaAngle = targetAngle - currentAngle
    if math.abs(deltaAngle) <= 0.0001 then
        return
    end

    self.transform:RotateAround(cachedCenterPosition, normalizedAxis, deltaAngle)
    if KeepOriginalRotation then
        self.transform.rotation = baseWorldRotation
    end
    currentAngle = targetAngle
end

function Awake()
    local alreadyInitialized = hasInitialized
    EnsureInitialized()
    if not alreadyInitialized then
        CaptureBaseState()
        ResetToBase()
    end
end

function ResetToBase()
    EnsureInitialized()

    self.transform.position = baseWorldPosition
    self.transform.rotation = baseWorldRotation
    cachedCenterPosition = ResolveCenterPosition()
    elapsedTime = 0
    currentAngle = 0
    isPlaying = false
    isComplete = true
end

function BeginForward()
    EnsureInitialized()
    ResetToBase()
    isComplete = false

    if totalDuration <= 0.0001 or totalAngle <= 0.0001 then
        isPlaying = false
        isComplete = true
        return
    end

    isPlaying = true
end

function BeginBackward()
    BeginForward()
end

function Tick(deltaTime)
    EnsureInitialized()
    if not isPlaying or isComplete then
        return
    end

    elapsedTime = elapsedTime + deltaTime
    if elapsedTime >= totalDuration then
        self.transform.position = baseWorldPosition
        self.transform.rotation = baseWorldRotation
        elapsedTime = totalDuration
        currentAngle = 0
        isPlaying = false
        isComplete = true
        return
    end

    ApplyAngle(GetAngleAtTime(elapsedTime))
end

function IsComplete()
    return isComplete
end

function GetProgress01()
    if totalDuration <= 0.0001 then
        return 1
    end
    if isComplete then
        return 1
    end
    return Clamp01(elapsedTime / totalDuration)
end

function GetTotalDuration()
    return totalDuration
end

function GetSpeedFactor()
    if maxAngularSpeed <= 0.0001 or totalDuration <= 0.0001 then
        return 0
    end

    local t = elapsedTime
    if t <= 0 then
        return 0
    end

    if AccelDuration > 0 then
        if t < AccelDuration then
            return Clamp01(t / AccelDuration)
        end
        t = t - AccelDuration
    end

    if CruiseDuration > 0 then
        if t < CruiseDuration then
            return 1
        end
        t = t - CruiseDuration
    end

    if DecelDuration > 0 and t < DecelDuration then
        return Clamp01(1 - (t / DecelDuration))
    end

    return 0
end
