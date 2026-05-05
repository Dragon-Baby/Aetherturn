---@var Registry               :DouyinScript
---@var DelayAfterPendulum     :float = 0
---@var DelayAfterExtend       :float = 0
---@var DelayAfterBallRotate   :float = 0
---@var DelayAfterCenterSpin   :float = 0
---@var DelayAfterBallReset    :float = 0
---@var DelayAfterRetract      :float = 0
---@var AutoPlay               :bool = true
---@var LoopSequence           :bool = true
---@var EnableDebugLog         :bool = false
---@end

local STATE_IDLE = 0
local STATE_PENDULUM = 1
local STATE_EXTEND = 2
local STATE_BALL_ROTATE = 3
local STATE_CENTER_SPIN = 4
local STATE_BALL_RESET = 5
local STATE_RETRACT = 6
local STATE_WAIT = 7

local currentState = STATE_IDLE
local isPlaying = false
local waitTimer = 0
local waitNextState = STATE_IDLE

local function Log(message)
    if EnableDebugLog then
        print("[DouyinSequenceController] " .. tostring(message))
    end
end

local function ClampNonNegative(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    if value < 0 then
        return 0
    end
    return value
end

local function HasRegistry()
    return Registry ~= nil and Registry.script ~= nil
end

local function EnterState(state)
    currentState = state
    Log("EnterState=" .. tostring(state))
end

local function BeginState(state)
    if not HasRegistry() then
        EnterState(STATE_IDLE)
        isPlaying = false
        return
    end

    if state == STATE_PENDULUM then
        Registry.script.BeginPendulums()
    elseif state == STATE_EXTEND then
        Registry.script.BeginExtendForward()
    elseif state == STATE_BALL_ROTATE then
        Registry.script.BeginBallForward()
    elseif state == STATE_CENTER_SPIN then
        Registry.script.BeginOrbit()
        Registry.script.BeginOrbitFx(Registry.script.GetOrbitDuration())
    elseif state == STATE_BALL_RESET then
        Registry.script.BeginBallBackward()
    elseif state == STATE_RETRACT then
        Registry.script.BeginExtendBackward()
    end

    EnterState(state)
end

local function EnterWaitState(duration, nextState)
    local waitDuration = ClampNonNegative(duration, 0)
    if waitDuration <= 0 then
        BeginState(nextState)
        return
    end

    waitTimer = waitDuration
    waitNextState = nextState
    EnterState(STATE_WAIT)
end

function Awake()
    if AutoPlay == nil then
        AutoPlay = true
    end
    if LoopSequence == nil then
        LoopSequence = true
    end
    if EnableDebugLog == nil then
        EnableDebugLog = false
    end

    if HasRegistry() then
        Registry.script.Validate()
        Registry.script.CollectAll()
        Registry.script.ResetAllToBase()
        Registry.script.SetAllVertexLightIntensityScale(Registry.script.GetCurrentNightBlend01())
    else
        Log("Registry is nil or Registry.script is nil")
    end

    isPlaying = AutoPlay and HasRegistry()
    if isPlaying then
        BeginState(STATE_PENDULUM)
    else
        EnterState(STATE_IDLE)
    end
end

function Update()
    if not isPlaying or not HasRegistry() then
        return
    end

    local deltaTime = CS.UnityEngine.Time.deltaTime
    Registry.script.TickVertexLights(deltaTime)

    local gearDriveFactor = nil
    if currentState == STATE_CENTER_SPIN then
        gearDriveFactor = Registry.script.GetOrbitSpeedFactor()
    end
    Registry.script.TickGears(deltaTime, gearDriveFactor)

    if currentState == STATE_WAIT then
        waitTimer = waitTimer - deltaTime
        if waitTimer <= 0 then
            waitTimer = 0
            BeginState(waitNextState)
        end
        return
    end

    if currentState == STATE_PENDULUM then
        Registry.script.TickPendulums(deltaTime)
        if Registry.script.ArePendulumsComplete() then
            EnterWaitState(DelayAfterPendulum, STATE_EXTEND)
        end
        return
    end

    if currentState == STATE_EXTEND then
        Registry.script.TickExtenders(deltaTime)
        if Registry.script.AreExtendersComplete() then
            EnterWaitState(DelayAfterExtend, STATE_BALL_ROTATE)
        end
        return
    end

    if currentState == STATE_BALL_ROTATE then
        Registry.script.TickBalls(deltaTime)
        if Registry.script.AreBallsComplete() then
            EnterWaitState(DelayAfterBallRotate, STATE_CENTER_SPIN)
        end
        return
    end

    if currentState == STATE_CENTER_SPIN then
        Registry.script.TickOrbit(deltaTime)
        local orbitProgress = Registry.script.GetOrbitProgress01()
        Registry.script.TickOrbitFx(deltaTime, orbitProgress)
        Registry.script.SetAllVertexLightIntensityScale(Registry.script.GetOrbitNightBlend01(orbitProgress))
        if Registry.script.IsOrbitComplete() then
            Registry.script.CompleteOrbitFx()
            EnterWaitState(DelayAfterCenterSpin, STATE_BALL_RESET)
        end
        return
    end

    if currentState == STATE_BALL_RESET then
        Registry.script.TickBalls(deltaTime)
        if Registry.script.AreBallsComplete() then
            EnterWaitState(DelayAfterBallReset, STATE_RETRACT)
        end
        return
    end

    if currentState == STATE_RETRACT then
        Registry.script.TickExtenders(deltaTime)
        if Registry.script.AreExtendersComplete() then
            if LoopSequence then
                EnterWaitState(DelayAfterRetract, STATE_PENDULUM)
            else
                Registry.script.ResetAllToBase()
                Registry.script.SetAllVertexLightIntensityScale(Registry.script.GetCurrentNightBlend01())
                EnterState(STATE_IDLE)
                isPlaying = false
            end
        end
    end
end

function PlaySequence()
    if not HasRegistry() then
        Log("PlaySequence skipped because Registry is unavailable")
        return
    end

    Registry.script.CollectAll()
    if currentState == STATE_IDLE then
        BeginState(STATE_PENDULUM)
    end
    isPlaying = true
end

function PauseSequence()
    isPlaying = false
end

function ResumeSequence()
    if HasRegistry() then
        isPlaying = true
    end
end

function RestartSequence()
    if not HasRegistry() then
        return
    end

    Registry.script.CollectAll()
    Registry.script.ResetAllToBase()
    Registry.script.SetAllVertexLightIntensityScale(Registry.script.GetCurrentNightBlend01())
    waitTimer = 0
    waitNextState = STATE_IDLE
    isPlaying = true
    BeginState(STATE_PENDULUM)
end

function StopSequence()
    isPlaying = false
    waitTimer = 0
    waitNextState = STATE_IDLE

    if HasRegistry() then
        Registry.script.ResetAllToBase()
        Registry.script.SetAllVertexLightIntensityScale(Registry.script.GetCurrentNightBlend01())
    end

    EnterState(STATE_IDLE)
end

function GetCurrentState()
    return currentState
end
