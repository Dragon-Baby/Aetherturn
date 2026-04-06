---@var MoveAxis        :Vector3
---@var UseLocalSpace   :bool = true
---@var MoveDistance    :float = 1
---@var MoveSpeed       :float = 0.5
---@var StopDuration    :float = 0
---@var AutoPlay        :bool = true
---@var StartAtEnd      :bool = false
---@var PingPong        :bool = true
---@end

local moveAxis = nil
local baseLocalPosition = nil
local baseWorldPosition = nil
local currentDistance = 0
local moveDirection = 1
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
    if MoveAxis == nil or MoveAxis.sqrMagnitude <= 0.0001 then
        MoveAxis = CS.UnityEngine.Vector3.right
    end

    moveAxis = MoveAxis.normalized
end

local function BuildOffset(distance)
    return CS.UnityEngine.Vector3(
        moveAxis.x * distance,
        moveAxis.y * distance,
        moveAxis.z * distance
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

local function ReachEnd(distance, nextDirection)
    currentDistance = distance
    ApplyCurrentDistance()

    if PingPong then
        moveDirection = nextDirection
        stopTimer = StopDuration
    else
        isPlaying = false
    end
end

function Awake()
    MoveDistance = ClampNonNegative(MoveDistance, 1)
    MoveSpeed = ClampNonNegative(MoveSpeed, 0.5)
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

    baseLocalPosition = self.transform.localPosition
    baseWorldPosition = self.transform.position

    currentDistance = StartAtEnd and MoveDistance or 0
    moveDirection = StartAtEnd and -1 or 1
    stopTimer = 0
    isPlaying = AutoPlay

    ApplyCurrentDistance()
end

function Update()
    if not isPlaying then
        return
    end

    if MoveDistance <= 0 or MoveSpeed <= 0 then
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

    currentDistance = currentDistance + moveDirection * MoveSpeed * deltaTime

    if currentDistance >= MoveDistance then
        ReachEnd(MoveDistance, -1)
        return
    end

    if currentDistance <= 0 then
        ReachEnd(0, 1)
        return
    end

    ApplyCurrentDistance()
end

function Play()
    isPlaying = true
end

function Pause()
    isPlaying = false
end

function Stop()
    isPlaying = false
    currentDistance = 0
    moveDirection = 1
    stopTimer = 0
    ApplyCurrentDistance()
end

function ResetToStart()
    currentDistance = 0
    moveDirection = 1
    stopTimer = 0
    ApplyCurrentDistance()
end

function ResetToEnd()
    currentDistance = MoveDistance
    moveDirection = -1
    stopTimer = 0
    ApplyCurrentDistance()
end

function SetSpeed(speed)
    MoveSpeed = ClampNonNegative(speed, MoveSpeed)
end

function SetDistance(distance)
    MoveDistance = ClampNonNegative(distance, MoveDistance)
    if currentDistance > MoveDistance then
        currentDistance = MoveDistance
        ApplyCurrentDistance()
    end
end

function SetStopDuration(duration)
    StopDuration = ClampNonNegative(duration, StopDuration)
end

function SetMoveAxis(axis)
    MoveAxis = axis
    RefreshAxis()
    ApplyCurrentDistance()
end

function SetUseLocalSpace(useLocal)
    UseLocalSpace = useLocal
    ApplyCurrentDistance()
end

function SetPingPong(enable)
    PingPong = enable
end

function SetPlaying(enable)
    isPlaying = enable
end
