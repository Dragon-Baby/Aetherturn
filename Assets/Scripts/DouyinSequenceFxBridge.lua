---@var SceneEnvironment       :DouyinSceneEnvironment
---@var OrbitPulseParticle     :UnityEngine.ParticleSystem
---@var OrbitPulseAudio        :UnityEngine.AudioSource
---@var OrbitPulseAudioObject  :UnityEngine.GameObject
---@var EnableOrbitPulseAudio  :bool = true
---@var OrbitPulseAudioVolume  :float = 1
---@var EnableEnvironmentSwitch:bool = false
---@var EnableDebugLog         :bool = true
---@var DayMainLightStrength   :float = 1
---@var NightMainLightStrength :float = 0
---@var DayEmissionIntensity   :float = 0
---@var NightEmissionIntensity :float = 1
---@var DaySkyColor            :Color
---@var DayEquatorColor        :Color
---@var DayGroundColor         :Color
---@var NightSkyColor          :Color
---@var NightEquatorColor      :Color
---@var NightGroundColor       :Color
---@var AmbientMaterials       :UnityEngine.Material[]
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

local function GetSceneEnvironmentSettings()
    if SceneEnvironment == nil then
        return nil
    end

    local ok, settings = pcall(function()
        return SceneEnvironment.settings
    end)
    if not ok then
        Log("SceneEnvironment.settings access failed: " .. tostring(settings))
        return nil
    end
    return settings
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

local function ResolveAudioSource(audioSource, audioObject)
    if audioSource ~= nil then
        return audioSource
    end

    if audioObject ~= nil then
        return audioObject:GetComponent(typeof(CS.UnityEngine.AudioSource))
    end

    return nil
end

local function PlayOrbitPulseAudio()
    if EnableOrbitPulseAudio == false then
        return
    end

    local audioSource = ResolveAudioSource(OrbitPulseAudio, OrbitPulseAudioObject)
    if audioSource == nil then
        return
    end

    local ok, errorMessage = pcall(function()
        audioSource.enabled = true
        audioSource.playOnAwake = false
        audioSource.loop = false
        audioSource.volume = Clamp01(OrbitPulseAudioVolume or 1)
        audioSource:Stop()
        audioSource:Play()
    end)
    if not ok then
        Log("Orbit pulse audio play failed: " .. tostring(errorMessage))
    end
end

local function StopOrbitPulseAudio()
    local audioSource = ResolveAudioSource(OrbitPulseAudio, OrbitPulseAudioObject)
    if audioSource == nil then
        return
    end

    local ok, errorMessage = pcall(function()
        audioSource:Stop()
    end)
    if not ok then
        Log("Orbit pulse audio stop failed: " .. tostring(errorMessage))
    end
end

local function LerpFloat(fromValue, toValue, t)
    return fromValue + (toValue - fromValue) * t
end

local function ResolveColor(value, fallback)
    if value ~= nil then
        return value
    end
    return fallback
end

local function ToUnityColor(value)
    if value == nil then
        return CS.UnityEngine.Color.black
    end

    return CS.UnityEngine.Color(value.r, value.g, value.b, value.a)
end

local function LerpColor(fromValue, toValue, t)
    return CS.UnityEngine.Color.Lerp(ToUnityColor(fromValue), ToUnityColor(toValue), t)
end

local function ApplyAmbientMaterialColors(skyColor, equatorColor, groundColor)
    if AmbientMaterials == nil then
        return
    end

    for i = 0, AmbientMaterials.Length - 1 do
        local material = AmbientMaterials[i]
        if material ~= nil then
            material:SetColor("_SkyColor", skyColor)
            material:SetColor("_EquatorColor", equatorColor)
            material:SetColor("_GroundColor", groundColor)
        end
    end
end

local function ApplyAmbientColors(nightBlend01)
    local skyColor = LerpColor(
        ResolveColor(DaySkyColor, CS.UnityEngine.Color.white),
        ResolveColor(NightSkyColor, CS.UnityEngine.Color.black),
        nightBlend01)
    local equatorColor = LerpColor(
        ResolveColor(DayEquatorColor, CS.UnityEngine.Color.white),
        ResolveColor(NightEquatorColor, CS.UnityEngine.Color.black),
        nightBlend01)
    local groundColor = LerpColor(
        ResolveColor(DayGroundColor, CS.UnityEngine.Color.white),
        ResolveColor(NightGroundColor, CS.UnityEngine.Color.black),
        nightBlend01)

    CS.UnityEngine.RenderSettings.ambientSkyColor = skyColor
    CS.UnityEngine.RenderSettings.ambientEquatorColor = equatorColor
    CS.UnityEngine.RenderSettings.ambientGroundColor = groundColor
    CS.UnityEngine.Shader.SetGlobalColor("_SkyColor", skyColor)
    CS.UnityEngine.Shader.SetGlobalColor("_EquatorColor", equatorColor)
    CS.UnityEngine.Shader.SetGlobalColor("_GroundColor", groundColor)
    ApplyAmbientMaterialColors(skyColor, equatorColor, groundColor)
end

local function ApplyEnvironmentBlend(nightBlend01)
    local settings = GetSceneEnvironmentSettings()
    if settings ~= nil then
        local ok, err = pcall(function()
            settings.mainLightStrength = LerpFloat(DayMainLightStrength or 1, NightMainLightStrength or 0, nightBlend01)
        end)
        if not ok then
            Log("settings.mainLightStrength write failed: " .. tostring(err))
        end
    end

    CS.UnityEngine.Shader.SetGlobalFloat(
        "_EmissionIntensity",
        LerpFloat(DayEmissionIntensity or 0, NightEmissionIntensity or 1, nightBlend01))
    ApplyAmbientColors(nightBlend01)
end

local function ResolveNightBlend01(reverseBlend, pulseProgress)
    local progress = Clamp01(pulseProgress)
    if reverseBlend ~= nil and reverseBlend > 0.5 then
        return 1 - progress
    end
    return progress
end

function ResetToBase()
    orbitPulseActive = false
    orbitPulseTargetReverseBlend = nil
    StopOrbitPulseAudio()

    local material = GetActiveSkyMaterial()
    if material ~= nil then
        ApplySkyPulse(material:GetFloat("_ReverseBlend"), 0)
        ApplyEnvironmentBlend(ResolveNightBlend01(material:GetFloat("_ReverseBlend"), 0))
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
        ApplyEnvironmentBlend(ResolveNightBlend01(orbitPulseTargetReverseBlend, 0))
    end

    if OrbitPulseParticle ~= nil then
        if OrbitPulseParticle.isPlaying then
            OrbitPulseParticle:Stop()
            OrbitPulseParticle:Clear()
        end
        OrbitPulseParticle:Play()
    end

    PlayOrbitPulseAudio()

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

    local pulseProgress = progress01 or 0
    ApplySkyPulse(reverseBlend, pulseProgress)
    ApplyEnvironmentBlend(ResolveNightBlend01(reverseBlend, pulseProgress))
end

function CompleteOrbitFx()
    if not orbitPulseActive then
        return
    end

    orbitPulseActive = false
    orbitPulseCycleCount = orbitPulseCycleCount + 1
end

function GetOrbitNightBlend01(progress01)
    local reverseBlend = orbitPulseTargetReverseBlend
    if reverseBlend == nil then
        local material = GetActiveSkyMaterial()
        if material ~= nil then
            reverseBlend = material:GetFloat("_ReverseBlend")
        else
            reverseBlend = 0
        end
    end

    return ResolveNightBlend01(reverseBlend, progress01)
end

function GetCurrentNightBlend01()
    local material = GetActiveSkyMaterial()
    if material == nil then
        return 0
    end

    return ResolveNightBlend01(material:GetFloat("_ReverseBlend"), material:GetFloat("_PulseProgress"))
end
