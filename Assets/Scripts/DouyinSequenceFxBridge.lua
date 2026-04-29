---@var SceneEnvironment       :DouyinSceneEnvironment
---@var OrbitPulseParticle     :UnityEngine.ParticleSystem
---@var EnableEnvironmentSwitch:bool = false
---@var EnableDebugLog         :bool = true
---@end

local orbitPulseActive = false
local orbitPulseCycleCount = 0
local orbitPulseTargetReverseBlend = nil

local function Log(message)
    if EnableDebugLog then
        print("[DouyinSequenceFxBridge] " .. tostring(message))
    end
end

local function GetActiveSkyMaterial()
    if SceneEnvironment == nil then
        return nil
    end

    local ok, material = pcall(function()
        return SceneEnvironment.settings.skyMaterial
    end)
    if not ok then
        Log("SceneEnvironment.settings.skyMaterial access failed: " .. tostring(material))
        return nil
    end
    return material
end

local function ApplySkyPulse(reverseBlend, pulseProgress)
    local material = GetActiveSkyMaterial()
    if material == nil then
        return
    end

    material:SetFloat("_ReverseBlend", reverseBlend)
    material:SetFloat("_PulseProgress", pulseProgress)
end

function ResetToBase()
    orbitPulseActive = false
    orbitPulseTargetReverseBlend = nil

    local material = GetActiveSkyMaterial()
    if material ~= nil then
        ApplySkyPulse(material:GetFloat("_ReverseBlend"), 0)
    end
end

function BeginOrbitFx(totalDuration)
    orbitPulseActive = totalDuration ~= nil and totalDuration > 0

    local material = GetActiveSkyMaterial()
    if material ~= nil then
        local currentReverseBlend = material:GetFloat("_ReverseBlend")
        if orbitPulseCycleCount > 0 then
            orbitPulseTargetReverseBlend = currentReverseBlend > 0.5 and 0 or 1
        else
            orbitPulseTargetReverseBlend = currentReverseBlend
        end
        ApplySkyPulse(orbitPulseTargetReverseBlend, 0)
    end

    if OrbitPulseParticle ~= nil then
        if OrbitPulseParticle.isPlaying then
            OrbitPulseParticle:Stop()
            OrbitPulseParticle:Clear()
        end
        OrbitPulseParticle:Play()
    end

    if EnableEnvironmentSwitch then
        Log("EnableEnvironmentSwitch is true, but custom environment switching remains intentionally isolated.")
    end
end

function TickOrbitFx(deltaTime, progress01)
    if not orbitPulseActive then
        return
    end

    local material = GetActiveSkyMaterial()
    if material == nil then
        return
    end

    local reverseBlend = orbitPulseTargetReverseBlend
    if reverseBlend == nil then
        reverseBlend = material:GetFloat("_ReverseBlend")
        orbitPulseTargetReverseBlend = reverseBlend
    end

    ApplySkyPulse(reverseBlend, progress01 or 0)
end

function CompleteOrbitFx()
    if not orbitPulseActive then
        return
    end

    orbitPulseActive = false
    orbitPulseCycleCount = orbitPulseCycleCount + 1
end
