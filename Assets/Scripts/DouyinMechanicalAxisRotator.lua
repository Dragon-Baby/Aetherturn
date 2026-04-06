---@var RotationAxis    :Vector3
---@var UseLocalSpace   :bool = true
---@var RotateAngle     :float = 90
---@var RotateSpeed     :float = 45
---@var StopDuration    :float = 0
---@var AutoPlay        :bool = true
---@var StartAtEnd      :bool = false
---@var PingPong        :bool = true
---@end

local rotationAxis = nil
local currentAngle = 0
local rotateDirection = 1
local stopTimer = 0
local isPlaying = true

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
    if RotationAxis == nil or RotationAxis.sqrMagnitude <= 0.0001 then
        RotationAxis = CS.UnityEngine.Vector3.up
    end

    rotationAxis = RotationAxis.normalized
end

local function GetRotationSpace()
    return UseLocalSpace and CS.UnityEngine.Space.Self or CS.UnityEngine.Space.World
end

local function ApplyDeltaAngle(deltaAngle)
    if math.abs(deltaAngle) <= 0.0001 then
        return
    end

    self.transform:Rotate(rotationAxis, deltaAngle, GetRotationSpace())
end

local function ReachEnd(angle, nextDirection)
    local deltaAngle = angle - currentAngle
    currentAngle = angle
    ApplyDeltaAngle(deltaAngle)

    if PingPong then
        rotateDirection = nextDirection
        stopTimer = StopDuration
    else
        isPlaying = false
    end
end

function Awake()
    RotateAngle = ClampNonNegative(RotateAngle, 90)
    RotateSpeed = ClampNonNegative(RotateSpeed, 45)
    StopDuration = ClampNonNegative(StopDuration, 0)

    if AutoPlay == nil then
        AutoPlay = true
    end
    if StartAtEnd == nil then
        StartAtEnd = false
    end
    if PingPong == nil then
        PingPong = true
    end

    RefreshAxis()

    currentAngle = StartAtEnd and RotateAngle or 0
    rotateDirection = StartAtEnd and -1 or 1
    stopTimer = 0
    isPlaying = AutoPlay

    ApplyDeltaAngle(currentAngle)
end

function Update()
    if not isPlaying then
        return
    end

    if RotateAngle <= 0 or RotateSpeed <= 0 then
        return
    end

    local deltaTime = CS.UnityEngine.Time.deltaTime

    if stopTimer > 0 then
        stopTimer = stopTimer - deltaTime
        if stopTimer > 0 then
            return
        end
        stopTimer = 0
    end

    local nextAngle = currentAngle + rotateDirection * RotateSpeed * deltaTime

    if nextAngle >= RotateAngle then
        ReachEnd(RotateAngle, -1)
        return
    end

    if nextAngle <= 0 then
        ReachEnd(0, 1)
        return
    end

    local deltaAngle = nextAngle - currentAngle
    currentAngle = nextAngle
    ApplyDeltaAngle(deltaAngle)
end

function Play()
    isPlaying = true
end

function Pause()
    isPlaying = false
end

function Stop()
    isPlaying = false
    ResetToStart()
end

function ResetToStart()
    local deltaAngle = -currentAngle
    currentAngle = 0
    rotateDirection = 1
    stopTimer = 0
    ApplyDeltaAngle(deltaAngle)
end

function ResetToEnd()
    local deltaAngle = RotateAngle - currentAngle
    currentAngle = RotateAngle
    rotateDirection = -1
    stopTimer = 0
    ApplyDeltaAngle(deltaAngle)
end

function SetSpeed(speed)
    RotateSpeed = ClampNonNegative(speed, RotateSpeed)
end

function SetAngle(angle)
    RotateAngle = ClampNonNegative(angle, RotateAngle)
    if currentAngle > RotateAngle then
        local deltaAngle = RotateAngle - currentAngle
        currentAngle = RotateAngle
        ApplyDeltaAngle(deltaAngle)
    end
end

function SetStopDuration(duration)
    StopDuration = ClampNonNegative(duration, StopDuration)
end

function SetRotationAxis(axis)
    RotationAxis = axis
    RefreshAxis()
end

function SetUseLocalSpace(useLocal)
    UseLocalSpace = useLocal
end

function SetPingPong(enable)
    PingPong = enable
end

function SetPlaying(enable)
    isPlaying = enable
end
