---@var UnitObjects            :UnityEngine.GameObject[]
---@var UnitScriptName         :string = "DouyinSequenceGearUnit"
---@var MinSpeedFactor         :float = 0.1
---@end

local units = {}

local function Clamp01(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function AppendUnit(target)
    if target ~= nil and target.script ~= nil then
        table.insert(units, target)
    end
end

local function CollectFromObject(gameObject)
    if gameObject == nil or UnitScriptName == nil or UnitScriptName == "" then
        return
    end

    local scriptRef = gameObject:GetDouyinScript(UnitScriptName)
    AppendUnit(scriptRef)
end

function CollectUnits()
    units = {}

    if UnitObjects == nil then
        return
    end

    local count = UnitObjects.Length or 0
    for i = 0, count - 1 do
        CollectFromObject(UnitObjects[i])
    end
end

function Awake()
    if UnitScriptName == nil or UnitScriptName == "" then
        UnitScriptName = "DouyinSequenceGearUnit"
    end
    if MinSpeedFactor == nil then
        MinSpeedFactor = 0.1
    end
    CollectUnits()
end

function ResetToBase()
    for i = 1, #units do
        units[i].script.ResetToBase()
    end
end

function Tick(deltaTime, driveFactor)
    local minFactor = Clamp01(MinSpeedFactor, 0.1)
    local targetFactor = driveFactor
    if targetFactor == nil then
        targetFactor = 0
    end
    local finalFactor = minFactor + (1 - minFactor) * Clamp01(targetFactor, 0)

    for i = 1, #units do
        units[i].script.Tick(deltaTime, finalFactor)
    end
end

function IsComplete()
    return true
end
