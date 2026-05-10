---@var EnableAudio            :bool = true
---@var MasterVolume           :float = 1
---@var PendulumAudio          :UnityEngine.AudioSource
---@var PendulumAudioObject    :UnityEngine.GameObject
---@var ExtendAudio            :UnityEngine.AudioSource
---@var ExtendAudioObject      :UnityEngine.GameObject
---@var RotateAudio            :UnityEngine.AudioSource
---@var RotateAudioObject      :UnityEngine.GameObject
---@var SpinAudio              :UnityEngine.AudioSource
---@var SpinAudioObject        :UnityEngine.GameObject
---@var EnableDebugLog         :bool = false
---@end

local oneShotSources = {}
local continuousSource = nil

local function Log(message)
    if EnableDebugLog then
        print("[DouyinSequenceAudioBridge] " .. tostring(message))
    end
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

local function EnsureDefaults()
    if EnableAudio == nil then
        EnableAudio = true
    end
    if MasterVolume == nil then
        MasterVolume = 1
    end
    if EnableDebugLog == nil then
        EnableDebugLog = false
    end
end

local function AddUnique(list, value)
    if value == nil then
        return
    end

    for i = 1, #list do
        if list[i] == value then
            return
        end
    end

    table.insert(list, value)
end

local function ResolveAudioSource(audioSource, audioObject)
    if audioSource ~= nil then
        return audioSource
    end

    if audioObject ~= nil then
        return audioObject:GetComponent(typeof(CS.UnityEngine.AudioSource))
    end

    return nil
end

local function GetPendulumAudio()
    return ResolveAudioSource(PendulumAudio, PendulumAudioObject)
end

local function GetExtendAudio()
    return ResolveAudioSource(ExtendAudio, ExtendAudioObject)
end

local function GetRotateAudio()
    return ResolveAudioSource(RotateAudio, RotateAudioObject)
end

local function GetSpinAudio()
    return ResolveAudioSource(SpinAudio, SpinAudioObject)
end

local function CollectConfiguredSources()
    local sources = {}
    AddUnique(sources, GetPendulumAudio())
    AddUnique(sources, GetExtendAudio())
    AddUnique(sources, GetRotateAudio())
    AddUnique(sources, GetSpinAudio())
    return sources
end

local function SetEnabled(audioSource, enabled)
    if audioSource == nil then
        return
    end

    local ok, errorMessage = pcall(function()
        audioSource.enabled = enabled
    end)
    if not ok then
        Log("SetEnabled failed: " .. tostring(errorMessage))
    end
end

local function SafeStop(audioSource)
    if audioSource == nil then
        return
    end

    local ok, errorMessage = pcall(function()
        audioSource:Stop()
    end)
    if not ok then
        Log("Stop failed: " .. tostring(errorMessage))
    end
end

local function PrepareAudio(audioSource, shouldLoop)
    if audioSource == nil then
        return false
    end

    SetEnabled(audioSource, true)
    pcall(function()
        audioSource.playOnAwake = false
    end)
    pcall(function()
        audioSource.loop = shouldLoop
    end)
    pcall(function()
        audioSource.volume = Clamp01(MasterVolume)
    end)

    return true
end

local function PlayFromStart(audioSource, shouldLoop)
    if not PrepareAudio(audioSource, shouldLoop) then
        return false
    end

    SafeStop(audioSource)
    local ok, errorMessage = pcall(function()
        audioSource:Play()
    end)
    if not ok then
        Log("Play failed: " .. tostring(errorMessage))
        return false
    end

    return true
end

local function StopAndDisable(audioSource)
    SafeStop(audioSource)
    SetEnabled(audioSource, false)
end

local function RemoveOneShot(audioSource)
    local nextSources = {}
    for i = 1, #oneShotSources do
        if oneShotSources[i] ~= audioSource then
            AddUnique(nextSources, oneShotSources[i])
        end
    end
    oneShotSources = nextSources
end

local function StopContinuousIfDifferent(nextSource)
    if continuousSource ~= nil and continuousSource ~= nextSource then
        StopAndDisable(continuousSource)
        continuousSource = nil
    end
end

local function BeginContinuous(audioSource, label)
    StopContinuousIfDifferent(audioSource)
    if PlayFromStart(audioSource, true) then
        continuousSource = audioSource
        RemoveOneShot(audioSource)
        Log("Begin continuous " .. tostring(label))
    end
end

local function BeginOneShot(audioSource, label)
    StopContinuousIfDifferent(nil)
    if PlayFromStart(audioSource, false) then
        AddUnique(oneShotSources, audioSource)
        Log("Begin one-shot " .. tostring(label))
    end
end

function Awake()
    EnsureDefaults()
end

function ResetToBase()
    EnsureDefaults()
    StopAll(true)
end

function BeginState(stateName)
    EnsureDefaults()

    if not EnableAudio then
        StopAll(true)
        return
    end

    if stateName == "Pendulum" then
        BeginContinuous(GetPendulumAudio(), stateName)
        return
    end

    if stateName == "CenterSpin" then
        BeginContinuous(GetSpinAudio(), stateName)
        return
    end

    if stateName == "ExtendForward" or stateName == "Retract" then
        BeginOneShot(GetExtendAudio(), stateName)
        return
    end

    if stateName == "BallRotate" or stateName == "BallReset" then
        BeginOneShot(GetRotateAudio(), stateName)
        return
    end

    StopContinuousIfDifferent(nil)
end

function Tick(deltaTime)
    EnsureDefaults()

    local nextSources = {}
    for i = 1, #oneShotSources do
        local audioSource = oneShotSources[i]
        if audioSource ~= nil and audioSource.isPlaying then
            AddUnique(nextSources, audioSource)
        else
            SetEnabled(audioSource, false)
        end
    end
    oneShotSources = nextSources
end

function PauseAll()
    local sources = CollectConfiguredSources()
    for i = 1, #sources do
        local audioSource = sources[i]
        if audioSource ~= nil and audioSource.isPlaying then
            pcall(function()
                audioSource:Pause()
            end)
        end
    end
end

function ResumeActive()
    if continuousSource ~= nil then
        SetEnabled(continuousSource, true)
        pcall(function()
            continuousSource:UnPause()
        end)
    end

    for i = 1, #oneShotSources do
        local audioSource = oneShotSources[i]
        if audioSource ~= nil then
            SetEnabled(audioSource, true)
            pcall(function()
                audioSource:UnPause()
            end)
        end
    end
end

function StopAll(disableSources)
    if disableSources == nil then
        disableSources = true
    end

    local sources = CollectConfiguredSources()
    for i = 1, #sources do
        local audioSource = sources[i]
        SafeStop(audioSource)
        if disableSources then
            SetEnabled(audioSource, false)
        end
    end

    oneShotSources = {}
    continuousSource = nil
end
