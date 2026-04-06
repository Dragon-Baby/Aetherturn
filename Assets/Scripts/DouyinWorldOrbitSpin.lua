---@var OrbitCenter          :UnityEngine.Transform
---@var OrbitCenterPosition  :Vector3
---@var OrbitAxis            :Vector3
---@var OrbitLoops           :float = 1
---@var AccelDuration        :float = 1
---@var CruiseDuration       :float = 0.5
---@var DecelDuration        :float = 1
---@var AutoPlay             :bool = true
---@var KeepOriginalRotation :bool = false
---@end

local orbitAxis = nil
local initialWorldPosition = nil
local initialWorldRotation = nil
local cachedCenterPosition = nil
local elapsedTime = 0
local currentAngle = 0
local totalAngle = 360
local totalDuration = 0
local maxAngularSpeed = 0
local accelRate = 0
local decelRate = 0
local isPlaying = false
local hasCapturedStart = false

local function ClampNonNegative(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    if value < 0 then
        return 0
    end
    return value
end

local function RefreshAxis()
    if OrbitAxis == nil or OrbitAxis.sqrMagnitude <= 0.0001 then
        OrbitAxis = CS.UnityEngine.Vector3.up
    end

    orbitAxis = OrbitAxis.normalized
end

local function ResolveCenterPosition()
    if OrbitCenter ~= nil then
        return OrbitCenter.position
    end

    if OrbitCenterPosition ~= nil then
        return OrbitCenterPosition
    end

    return self.transform.position
end

local function RebuildMotionProfile()
    OrbitLoops = ClampNonNegative(OrbitLoops, 1)
    AccelDuration = ClampNonNegative(AccelDuration, 1)
    CruiseDuration = ClampNonNegative(CruiseDuration, 0.5)
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

local function CaptureStartState()
    RefreshAxis()
    RebuildMotionProfile()

    initialWorldPosition = self.transform.position
    initialWorldRotation = self.transform.rotation
    cachedCenterPosition = ResolveCenterPosition()
    elapsedTime = 0
    currentAngle = 0
    hasCapturedStart = true
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

    if DecelDuration > 0 then
        if t < DecelDuration then
            return angle + maxAngularSpeed * t - 0.5 * decelRate * t * t
        end
    end

    return totalAngle
end

local function ApplyAngle(targetAngle)
    local deltaAngle = targetAngle - currentAngle
    if math.abs(deltaAngle) <= 0.0001 then
        return
    end

    self.transform:RotateAround(cachedCenterPosition, orbitAxis, deltaAngle)
    if KeepOriginalRotation then
        self.transform.rotation = initialWorldRotation
    end
    currentAngle = targetAngle
end

local function FinishOrbit()
    self.transform.position = initialWorldPosition
    self.transform.rotation = initialWorldRotation
    elapsedTime = totalDuration
    currentAngle = 0
    isPlaying = false
end

function Awake()
    if AutoPlay == nil then
        AutoPlay = true
    end
    if KeepOriginalRotation == nil then
        KeepOriginalRotation = false
    end

    CaptureStartState()
    isPlaying = AutoPlay
end

function Update()
    if not isPlaying then
        return
    end

    if not hasCapturedStart then
        CaptureStartState()
    end

    local deltaTime = CS.UnityEngine.Time.deltaTime
    elapsedTime = elapsedTime + deltaTime

    if elapsedTime >= totalDuration then
        FinishOrbit()
        return
    end

    ApplyAngle(GetAngleAtTime(elapsedTime))
end

function Play()
    isPlaying = true
end

function Pause()
    isPlaying = false
end

function Restart()
    CaptureStartState()
    self.transform.position = initialWorldPosition
    self.transform.rotation = initialWorldRotation
    isPlaying = true
end

function StopAndReset()
    if not hasCapturedStart then
        return
    end

    self.transform.position = initialWorldPosition
    self.transform.rotation = initialWorldRotation
    elapsedTime = 0
    currentAngle = 0
    isPlaying = false
end

function SetOrbitCenterTransform(center)
    OrbitCenter = center
end

function SetOrbitCenterPosition(worldPos)
    OrbitCenterPosition = worldPos
end

function SetOrbitAxis(axis)
    OrbitAxis = axis
    RefreshAxis()
end

function SetOrbitLoops(loops)
    OrbitLoops = ClampNonNegative(loops, OrbitLoops)
    RebuildMotionProfile()
end

function SetDurations(accel, cruise, decel)
    AccelDuration = ClampNonNegative(accel, AccelDuration)
    CruiseDuration = ClampNonNegative(cruise, CruiseDuration)
    DecelDuration = ClampNonNegative(decel, DecelDuration)
    RebuildMotionProfile()
end

function SetKeepOriginalRotation(keepRotation)
    KeepOriginalRotation = keepRotation
end

function IsPlaying()
    return isPlaying
end
