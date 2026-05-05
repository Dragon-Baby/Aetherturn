---@var LightObjects           :UnityEngine.GameObject[]
---@var LightScriptName        :string = "DouyinVertexLightUnit"
---@var MaxLightCount          :int = 8
---@var GlobalIntensityScale   :float = 1
---@var AutoCollectOnAwake     :bool = true
---@var EnableDebugLog         :bool = false
---@end

local DEFAULT_MAX_LIGHT_COUNT = 8
local lights = {}
local positionRadiusArray = nil
local colorIntensityArray = nil
local vectorZero = CS.UnityEngine.Vector4.zero

local function Log(message)
    if EnableDebugLog then
        print("[DouyinVertexLightManager] " .. tostring(message))
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

local function ResolveMaxLightCount()
    MaxLightCount = ClampNonNegative(MaxLightCount, DEFAULT_MAX_LIGHT_COUNT)
    if MaxLightCount < 1 then
        MaxLightCount = 1
    end
    if MaxLightCount > DEFAULT_MAX_LIGHT_COUNT then
        MaxLightCount = DEFAULT_MAX_LIGHT_COUNT
    end
    return MaxLightCount
end

local function EnsureArrays()
    local maxCount = ResolveMaxLightCount()
    if positionRadiusArray ~= nil and positionRadiusArray.Length == maxCount then
        return
    end

    positionRadiusArray = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector4), maxCount)
    colorIntensityArray = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector4), maxCount)
    for i = 0, maxCount - 1 do
        positionRadiusArray[i] = vectorZero
        colorIntensityArray[i] = vectorZero
    end
end

local function AppendLight(target)
    if target ~= nil and target.script ~= nil then
        table.insert(lights, target)
        return
    end

    if target ~= nil and target.GetPosition ~= nil then
        table.insert(lights, { script = target })
    end
end

local function ContainsLight(targetScript)
    if targetScript == nil then
        return false
    end

    for i = 1, #lights do
        if lights[i] ~= nil and lights[i].script == targetScript then
            return true
        end
    end
    return false
end

local function CollectFromObject(gameObject)
    if gameObject == nil or LightScriptName == nil or LightScriptName == "" then
        return
    end

    local scriptRef = gameObject:GetDouyinScript(LightScriptName)
    AppendLight(scriptRef)
end

local function ClearGlobalArrays()
    EnsureArrays()
    local maxCount = ResolveMaxLightCount()
    for i = 0, maxCount - 1 do
        positionRadiusArray[i] = vectorZero
        colorIntensityArray[i] = vectorZero
    end
    CS.UnityEngine.Shader.SetGlobalInt("_AetherVertexLightCount", 0)
    CS.UnityEngine.Shader.SetGlobalVectorArray("_AetherVertexLightPositionRadius", positionRadiusArray)
    CS.UnityEngine.Shader.SetGlobalVectorArray("_AetherVertexLightColorIntensity", colorIntensityArray)
end

function CollectLights()
    local registeredLights = lights
    lights = {}

    for i = 1, #registeredLights do
        if registeredLights[i] ~= nil and registeredLights[i].script ~= nil then
            AppendLight(registeredLights[i])
        end
    end

    if LightScriptName == nil or LightScriptName == "" then
        LightScriptName = "DouyinVertexLightUnit"
    end

    if LightObjects ~= nil then
        local count = LightObjects.Length or 0
        for i = 0, count - 1 do
            CollectFromObject(LightObjects[i])
        end
    end

    Log("Collected vertex lights: " .. tostring(#lights))
end

function RegisterLight(target)
    if target == nil then
        return
    end

    local targetScript = target.script or target
    if ContainsLight(targetScript) then
        return
    end

    AppendLight(target)
    ApplyGlobals()
end

function UnregisterLight(target)
    if target == nil then
        return
    end

    local targetScript = target.script or target
    for i = #lights, 1, -1 do
        if lights[i] ~= nil and lights[i].script == targetScript then
            table.remove(lights, i)
        end
    end
    ApplyGlobals()
end

function Awake()
    if LightScriptName == nil or LightScriptName == "" then
        LightScriptName = "DouyinVertexLightUnit"
    end
    if GlobalIntensityScale == nil then
        GlobalIntensityScale = 1
    end
    if AutoCollectOnAwake == nil then
        AutoCollectOnAwake = true
    end
    if EnableDebugLog == nil then
        EnableDebugLog = false
    end

    EnsureArrays()
    if AutoCollectOnAwake then
        CollectLights()
    end
    ApplyGlobals()
end

function ResetToBase()
    for i = 1, #lights do
        lights[i].script.ResetToBase()
    end
    ApplyGlobals()
end

function Tick(deltaTime)
    for i = 1, #lights do
        lights[i].script.Tick(deltaTime)
    end
    ApplyGlobals()
end

function ApplyGlobals()
    EnsureArrays()

    local maxCount = ResolveMaxLightCount()
    local activeCount = 0
    local scale = ClampNonNegative(GlobalIntensityScale, 1)

    for i = 0, maxCount - 1 do
        positionRadiusArray[i] = vectorZero
        colorIntensityArray[i] = vectorZero
    end

    for i = 1, #lights do
        if activeCount >= maxCount then
            break
        end

        local light = lights[i].script
        if light.IsActive() then
            local position = light.GetPosition()
            local radius = light.GetRadius()
            local color = light.GetColor()
            local intensity = light.GetIntensity() * scale

            positionRadiusArray[activeCount] = CS.UnityEngine.Vector4(position.x, position.y, position.z, radius)
            colorIntensityArray[activeCount] = CS.UnityEngine.Vector4(color.r, color.g, color.b, intensity)
            activeCount = activeCount + 1
        end
    end

    CS.UnityEngine.Shader.SetGlobalInt("_AetherVertexLightCount", activeCount)
    CS.UnityEngine.Shader.SetGlobalVectorArray("_AetherVertexLightPositionRadius", positionRadiusArray)
    CS.UnityEngine.Shader.SetGlobalVectorArray("_AetherVertexLightColorIntensity", colorIntensityArray)
end

function GetLightCount()
    return #lights
end

function SetGlobalIntensityScale(scale)
    GlobalIntensityScale = ClampNonNegative(scale, 0)
    ApplyGlobals()
end

function SetLightIntensity(lightIndex, intensity)
    local target = lights[lightIndex]
    if target == nil or target.script == nil then
        return
    end
    target.script.SetIntensity(intensity)
    ApplyGlobals()
end

function SetLightIntensityScale(lightIndex, scale)
    local target = lights[lightIndex]
    if target == nil or target.script == nil then
        return
    end
    target.script.SetIntensityScale(scale)
    ApplyGlobals()
end

function FadeLightIntensity(lightIndex, targetIntensity, duration)
    local target = lights[lightIndex]
    if target == nil or target.script == nil then
        return
    end
    target.script.FadeIntensity(targetIntensity, duration)
end

function FadeLightIntensityScale(lightIndex, targetScale, duration)
    local target = lights[lightIndex]
    if target == nil or target.script == nil then
        return
    end
    target.script.FadeIntensityScale(targetScale, duration)
end

function SetAllIntensityScale(scale)
    for i = 1, #lights do
        lights[i].script.SetIntensityScale(scale)
    end
    ApplyGlobals()
end

function FadeAllIntensityScale(targetScale, duration)
    for i = 1, #lights do
        lights[i].script.FadeIntensityScale(targetScale, duration)
    end
end

function ClearLights()
    lights = {}
    ClearGlobalArrays()
end
