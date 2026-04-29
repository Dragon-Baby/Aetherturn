---@var RotationAxis           :Vector3
---@var RotateSpeed            :float = 0
---@var UseLocalSpace          :bool = true
---@end

local baseLocalRotation = nil
local baseWorldRotation = nil
local normalizedAxis = nil
local hasInitialized = false

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
    normalizedAxis = NormalizeAxis(RotationAxis, CS.UnityEngine.Vector3.forward)
end

local function EnsureInitialized()
    if UseLocalSpace == nil then
        UseLocalSpace = true
    end
    if RotateSpeed == nil then
        RotateSpeed = 0
    end
    if normalizedAxis == nil then
        RefreshAxis()
    end
    if baseLocalRotation == nil then
        baseLocalRotation = self.transform.localRotation
    end
    if baseWorldRotation == nil then
        baseWorldRotation = self.transform.rotation
    end
    hasInitialized = true
end

local function GetSpace()
    return UseLocalSpace and CS.UnityEngine.Space.Self or CS.UnityEngine.Space.World
end

function Awake()
    local alreadyInitialized = hasInitialized
    EnsureInitialized()
    if not alreadyInitialized then
        ResetToBase()
    end
end

function ResetToBase()
    EnsureInitialized()
    if UseLocalSpace then
        self.transform.localRotation = baseLocalRotation
    else
        self.transform.rotation = baseWorldRotation
    end
end

function Tick(deltaTime, speedFactor)
    EnsureInitialized()
    local finalFactor = speedFactor or 1
    local deltaAngle = RotateSpeed * finalFactor * deltaTime
    if math.abs(deltaAngle) <= 0.0001 then
        return
    end
    self.transform:Rotate(normalizedAxis, deltaAngle, GetSpace())
end

function IsComplete()
    return true
end
