---@var UnitObjects            :UnityEngine.GameObject[]
---@var UnitScriptName         :string = "DouyinSequenceOrbitUnit"
---@var PrimaryUnitIndex       :int = 1
---@end

local units = {}
local isComplete = true

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

local function GetPrimaryUnit()
    if #units == 0 then
        return nil
    end

    local index = PrimaryUnitIndex or 1
    if index < 1 then
        index = 1
    end
    if index > #units then
        index = 1
    end
    return units[index]
end

function CollectUnits()
    units = {}

    if UnitObjects == nil then
        isComplete = true
        return
    end

    local count = UnitObjects.Length or 0
    for i = 0, count - 1 do
        CollectFromObject(UnitObjects[i])
    end

    isComplete = #units == 0
end

function Awake()
    if UnitScriptName == nil or UnitScriptName == "" then
        UnitScriptName = "DouyinSequenceOrbitUnit"
    end
    if PrimaryUnitIndex == nil or PrimaryUnitIndex < 1 then
        PrimaryUnitIndex = 1
    end
    CollectUnits()
end

function ResetToBase()
    for i = 1, #units do
        units[i].script.ResetToBase()
    end
    isComplete = #units == 0
end

function BeginForward()
    if #units == 0 then
        CollectUnits()
    end
    for i = 1, #units do
        units[i].script.BeginForward()
    end
    isComplete = #units == 0
end

function BeginBackward()
    BeginForward()
end

function Tick(deltaTime)
    if isComplete then
        return
    end
    local allCompleted = true
    for i = 1, #units do
        units[i].script.Tick(deltaTime)
        if not units[i].script.IsComplete() then
            allCompleted = false
        end
    end
    isComplete = allCompleted
end

function IsComplete()
    return isComplete
end

function GetSpeedFactor()
    local primary = GetPrimaryUnit()
    if primary == nil then
        return 0
    end
    return primary.script.GetSpeedFactor()
end

function GetProgress01()
    local primary = GetPrimaryUnit()
    if primary == nil then
        return 0
    end
    return primary.script.GetProgress01()
end

function GetTotalDuration()
    local primary = GetPrimaryUnit()
    if primary == nil then
        return 0
    end
    return primary.script.GetTotalDuration()
end
