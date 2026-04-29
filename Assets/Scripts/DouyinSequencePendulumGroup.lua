---@var UnitObjects            :UnityEngine.GameObject[]
---@var UnitScriptName         :string = "DouyinSequencePendulumUnit"
---@var SwingCount             :int = 17
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
        UnitScriptName = "DouyinSequencePendulumUnit"
    end
    if SwingCount == nil or SwingCount < 1 then
        SwingCount = 17
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
        units[i].script.BeginForward(SwingCount)
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
