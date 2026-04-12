---@var PendulumA               :UnityEngine.Transform
---@var PendulumB               :UnityEngine.Transform
---@var PendulumAxisA           :Vector3
---@var PendulumAxisB           :Vector3
---@var PendulumUseLocalA       :bool = true
---@var PendulumUseLocalB       :bool = true
---@var PendulumMaxAngleA       :float = 20
---@var PendulumMaxAngleB       :float = 20
---@var PendulumSpeedA          :float = 2
---@var PendulumSpeedB          :float = 2
---@var PendulumStartPhaseA     :float = 0
---@var PendulumStartPhaseB     :float = 0
---@var PendulumStopAngleA      :float = 0
---@var PendulumStopAngleB      :float = 0
---@var PendulumSwingCount      :int = 17

---@var ExtenderA               :UnityEngine.Transform
---@var ExtenderB               :UnityEngine.Transform
---@var ExtendAxisA             :Vector3
---@var ExtendAxisB             :Vector3
---@var ExtendUseLocalA         :bool = true
---@var ExtendUseLocalB         :bool = true
---@var ExtendDistanceA         :float = 1
---@var ExtendDistanceB         :float = 1
---@var ExtendSpeedA            :float = 0.5
---@var ExtendSpeedB            :float = 0.5

---@var BallA                   :UnityEngine.Transform
---@var BallB                   :UnityEngine.Transform
---@var BallAxisA               :Vector3
---@var BallAxisB               :Vector3
---@var BallUseLocalA           :bool = true
---@var BallUseLocalB           :bool = true
---@var BallRotateAngleA        :float = 90
---@var BallRotateAngleB        :float = 90
---@var BallRotateSpeedA        :float = 45
---@var BallRotateSpeedB        :float = 45

---@var CenterTransform         :UnityEngine.Transform
---@var CenterTransformB        :UnityEngine.Transform
---@var CenterTransformC        :UnityEngine.Transform
---@var CenterTransformD        :UnityEngine.Transform
---@var CenterOrbitPoint        :UnityEngine.Transform
---@var CenterOrbitPointB       :UnityEngine.Transform
---@var CenterOrbitPointC       :UnityEngine.Transform
---@var CenterOrbitPointD       :UnityEngine.Transform
---@var CenterUseLocalSpace     :bool = true
---@var CenterSpinLoops         :float = 2
---@var CenterAccelDuration     :float = 1
---@var CenterCruiseDuration    :float = 1
---@var CenterDecelDuration     :float = 1
---@var SceneEnvironment        :DouyinSceneEnvironment
---@var OrbitPulseParticle      :UnityEngine.ParticleSystem

---@var GearTransform1          :UnityEngine.Transform
---@var GearTransform2          :UnityEngine.Transform
---@var GearTransform3          :UnityEngine.Transform
---@var GearTransform4          :UnityEngine.Transform
---@var GearTransform5          :UnityEngine.Transform
---@var GearTransform6          :UnityEngine.Transform
---@var GearTransform7          :UnityEngine.Transform
---@var GearTransform8          :UnityEngine.Transform
---@var GearTransform9          :UnityEngine.Transform
---@var GearTransform10         :UnityEngine.Transform
---@var GearTransform11         :UnityEngine.Transform
---@var GearTransform12         :UnityEngine.Transform
---@var GearTransform13         :UnityEngine.Transform
---@var GearTransform14         :UnityEngine.Transform
---@var GearTransform15         :UnityEngine.Transform
---@var GearTransform16         :UnityEngine.Transform

---@var GearAxis1               :Vector3
---@var GearAxis2               :Vector3
---@var GearAxis3               :Vector3
---@var GearAxis4               :Vector3
---@var GearAxis5               :Vector3
---@var GearAxis6               :Vector3
---@var GearAxis7               :Vector3
---@var GearAxis8               :Vector3
---@var GearAxis9               :Vector3
---@var GearAxis10              :Vector3
---@var GearAxis11              :Vector3
---@var GearAxis12              :Vector3
---@var GearAxis13              :Vector3
---@var GearAxis14              :Vector3
---@var GearAxis15              :Vector3
---@var GearAxis16              :Vector3

---@var GearSpeed1              :float = 0
---@var GearSpeed2              :float = 0
---@var GearSpeed3              :float = 0
---@var GearSpeed4              :float = 0
---@var GearSpeed5              :float = 0
---@var GearSpeed6              :float = 0
---@var GearSpeed7              :float = 0
---@var GearSpeed8              :float = 0
---@var GearSpeed9              :float = 0
---@var GearSpeed10             :float = 0
---@var GearSpeed11             :float = 0
---@var GearSpeed12             :float = 0
---@var GearSpeed13             :float = 0
---@var GearSpeed14             :float = 0
---@var GearSpeed15             :float = 0
---@var GearSpeed16             :float = 0
---@var GearMinSpeedFactor      :float = 0.1

---@var DelayAfterPendulum      :float = 0
---@var DelayAfterExtend        :float = 0
---@var DelayAfterBallRotate    :float = 0
---@var DelayAfterCenterSpin    :float = 0
---@var DelayAfterBallReset     :float = 0
---@var DelayAfterRetract       :float = 0

---@var AutoPlay                :bool = true
---@var LoopSequence            :bool = true
---@end

local STATE_IDLE = 0
local STATE_PENDULUM = 1
local STATE_EXTEND = 2
local STATE_BALL_ROTATE = 3
local STATE_CENTER_SPIN = 4
local STATE_BALL_RESET = 5
local STATE_RETRACT = 6
local STATE_WAIT = 7

local TWO_PI = math.pi * 2

local currentState = STATE_IDLE
local isPlaying = false
local waitTimer = 0
local waitNextState = STATE_IDLE
local pendulums = {}
local extenders = {}
local balls = {}
local centerSpins = {}
local gears = {}
local orbitPulseActive = false
local orbitPulseElapsed = 0
local orbitPulseDuration = 0
local orbitPulseCompleted = false
local orbitPulseCycleCount = 0
local orbitPulseTargetReverseBlend = nil
local currentEnvironmentIndex = 0
local cachedSkyMaterials = {}
local pendingEnvironmentIndex = nil
local pendingEnvironmentTimer = 0
local pendingSourceEnvironmentIndex = nil
local pendingSourceMaterial = nil
local loggedSkyMaterialAccessFailure = false
local loggedSkyMaterialNil = false

local function ClampNonNegative(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    if value < 0 then
        return 0
    end
    return value
end

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

local function NormalizeAxis(axis, defaultAxis)
    if axis == nil or axis.sqrMagnitude <= 0.0001 then
        return defaultAxis
    end
    return axis.normalized
end

local function GetSpace(useLocal)
    return useLocal and CS.UnityEngine.Space.Self or CS.UnityEngine.Space.World
end

local function BuildVector(axis, value)
    return CS.UnityEngine.Vector3(axis.x * value, axis.y * value, axis.z * value)
end

local function MakePendulum(transformRef, axis, useLocal, maxAngle, speed, startPhase, stopAngle)
    if transformRef == nil then
        return nil
    end

    return {
        transform = transformRef,
        axis = NormalizeAxis(axis, CS.UnityEngine.Vector3.forward),
        useLocal = useLocal ~= false,
        maxAngle = ClampNonNegative(maxAngle, 20),
        speed = ClampNonNegative(speed, 2),
        startPhase = startPhase or 0,
        stopAngle = stopAngle or 0,
        phase = 0,
        lastAppliedAngle = 0,
        completedCycles = 0,
        baseLocalRotation = transformRef.localRotation,
        baseWorldRotation = transformRef.rotation
    }
end

local function ResetPendulum(pendulum)
    if pendulum == nil then
        return
    end

    if pendulum.useLocal then
        pendulum.transform.localRotation = pendulum.baseLocalRotation
    else
        pendulum.transform.rotation = pendulum.baseWorldRotation
    end

    pendulum.phase = pendulum.startPhase
    pendulum.lastAppliedAngle = 0
    pendulum.completedCycles = 0

    local initialAngle = math.sin(pendulum.phase) * pendulum.maxAngle
    pendulum.transform:Rotate(pendulum.axis, initialAngle, GetSpace(pendulum.useLocal))
    pendulum.lastAppliedAngle = initialAngle
end

local function UpdatePendulum(pendulum, deltaTime)
    if pendulum == nil then
        return true
    end

    local previousPhase = pendulum.phase
    pendulum.phase = pendulum.phase + pendulum.speed * deltaTime

    local previousCycles = math.floor((previousPhase - pendulum.startPhase) / TWO_PI)
    local currentCyclesCount = math.floor((pendulum.phase - pendulum.startPhase) / TWO_PI)
    if currentCyclesCount > previousCycles then
        pendulum.completedCycles = currentCyclesCount
    end

    local angle = math.sin(pendulum.phase) * pendulum.maxAngle
    local deltaAngle = angle - pendulum.lastAppliedAngle
    pendulum.transform:Rotate(pendulum.axis, deltaAngle, GetSpace(pendulum.useLocal))
    pendulum.lastAppliedAngle = angle

    return pendulum.completedCycles >= PendulumSwingCount
end

local function StopPendulumAtAngle(pendulum)
    if pendulum == nil then
        return
    end

    local deltaAngle = pendulum.stopAngle - pendulum.lastAppliedAngle
    pendulum.transform:Rotate(pendulum.axis, deltaAngle, GetSpace(pendulum.useLocal))
    pendulum.lastAppliedAngle = pendulum.stopAngle
end

local function MakeExtender(transformRef, axis, useLocal, distance, speed)
    if transformRef == nil then
        return nil
    end

    return {
        transform = transformRef,
        axis = NormalizeAxis(axis, CS.UnityEngine.Vector3.right),
        useLocal = useLocal ~= false,
        distance = ClampNonNegative(distance, 1),
        speed = ClampNonNegative(speed, 0.5),
        currentDistance = 0,
        baseLocalPosition = transformRef.localPosition,
        baseWorldPosition = transformRef.position
    }
end

local function ApplyExtenderDistance(extender, distance)
    if extender == nil then
        return
    end

    extender.currentDistance = distance
    local offset = BuildVector(extender.axis, distance)
    if extender.useLocal then
        extender.transform.localPosition = CS.UnityEngine.Vector3(
            extender.baseLocalPosition.x + offset.x,
            extender.baseLocalPosition.y + offset.y,
            extender.baseLocalPosition.z + offset.z
        )
    else
        extender.transform.position = CS.UnityEngine.Vector3(
            extender.baseWorldPosition.x + offset.x,
            extender.baseWorldPosition.y + offset.y,
            extender.baseWorldPosition.z + offset.z
        )
    end
end

local function ResetExtender(extender)
    if extender == nil then
        return
    end
    ApplyExtenderDistance(extender, 0)
end

local function UpdateExtender(extender, deltaTime, direction)
    if extender == nil then
        return true
    end

    if extender.distance <= 0 or extender.speed <= 0 then
        ApplyExtenderDistance(extender, direction > 0 and extender.distance or 0)
        return true
    end

    local nextDistance = extender.currentDistance + direction * extender.speed * deltaTime
    if direction > 0 then
        if nextDistance >= extender.distance then
            ApplyExtenderDistance(extender, extender.distance)
            return true
        end
    else
        if nextDistance <= 0 then
            ApplyExtenderDistance(extender, 0)
            return true
        end
    end

    ApplyExtenderDistance(extender, nextDistance)
    return false
end

local function MakeMechanicalRotator(transformRef, axis, useLocal, angle, speed)
    if transformRef == nil then
        return nil
    end

    return {
        transform = transformRef,
        axis = NormalizeAxis(axis, CS.UnityEngine.Vector3.up),
        useLocal = useLocal ~= false,
        angle = ClampNonNegative(angle, 90),
        speed = ClampNonNegative(speed, 45),
        currentAngle = 0,
        baseLocalRotation = transformRef.localRotation,
        baseWorldRotation = transformRef.rotation
    }
end

local function ResetMechanicalRotator(rotator)
    if rotator == nil then
        return
    end

    if rotator.useLocal then
        rotator.transform.localRotation = rotator.baseLocalRotation
    else
        rotator.transform.rotation = rotator.baseWorldRotation
    end
    rotator.currentAngle = 0
end

local function ApplyMechanicalRotation(rotator, angle)
    if rotator == nil then
        return
    end

    local deltaAngle = angle - rotator.currentAngle
    rotator.transform:Rotate(rotator.axis, deltaAngle, GetSpace(rotator.useLocal))
    rotator.currentAngle = angle
end

local function UpdateMechanicalRotator(rotator, deltaTime, direction)
    if rotator == nil then
        return true
    end

    if rotator.angle <= 0 or rotator.speed <= 0 then
        ApplyMechanicalRotation(rotator, direction > 0 and rotator.angle or 0)
        return true
    end

    local nextAngle = rotator.currentAngle + direction * rotator.speed * deltaTime
    if direction > 0 then
        if nextAngle >= rotator.angle then
            ApplyMechanicalRotation(rotator, rotator.angle)
            return true
        end
    else
        if nextAngle <= 0 then
            ApplyMechanicalRotation(rotator, 0)
            return true
        end
    end

    ApplyMechanicalRotation(rotator, nextAngle)
    return false
end

local function MakeGear(transformRef, axis, speed)
    if transformRef == nil then
        return nil
    end

    return {
        transform = transformRef,
        axis = NormalizeAxis(axis, CS.UnityEngine.Vector3.forward),
        speed = speed or 0,
        baseLocalRotation = transformRef.localRotation,
        baseWorldRotation = transformRef.rotation
    }
end

local function ResetGear(gear)
    if gear == nil then
        return
    end

    gear.transform.localRotation = gear.baseLocalRotation
end

local function UpdateGear(gear, deltaTime, speedFactor)
    if gear == nil then
        return
    end

    local deltaAngle = gear.speed * speedFactor * deltaTime
    if math.abs(deltaAngle) <= 0.0001 then
        return
    end

    gear.transform:Rotate(gear.axis, deltaAngle, CS.UnityEngine.Space.Self)
end

local function BuildCenterSpin(transformRef, orbitPointRef, useLocal, loops, accelDuration, cruiseDuration, decelDuration)
    if transformRef == nil then
        return nil
    end

    local spin = {
        transform = transformRef,
        orbitPointRef = orbitPointRef,
        useLocal = useLocal ~= false,
        loops = ClampNonNegative(loops, 2),
        accelDuration = ClampNonNegative(accelDuration, 1),
        cruiseDuration = ClampNonNegative(cruiseDuration, 1),
        decelDuration = ClampNonNegative(decelDuration, 1),
        elapsed = 0,
        currentAngle = 0,
        totalAngle = 0,
        totalDuration = 0,
        maxAngularSpeed = 0,
        accelRate = 0,
        decelRate = 0,
        centerPosition = transformRef.position,
        baseOffsetX = 0,
        baseOffsetY = 0,
        baseOffsetZ = 0,
        baseLocalPosition = transformRef.localPosition,
        baseWorldPosition = transformRef.position,
        baseLocalRotation = transformRef.localRotation,
        baseWorldRotation = transformRef.rotation
    }

    local effectiveTime = 0.5 * spin.accelDuration + spin.cruiseDuration + 0.5 * spin.decelDuration
    spin.totalAngle = 360 * spin.loops
    spin.totalDuration = spin.accelDuration + spin.cruiseDuration + spin.decelDuration
    if effectiveTime > 0.0001 and spin.totalAngle > 0.0001 then
        spin.maxAngularSpeed = spin.totalAngle / effectiveTime
        spin.accelRate = spin.accelDuration > 0 and (spin.maxAngularSpeed / spin.accelDuration) or 0
        spin.decelRate = spin.decelDuration > 0 and (spin.maxAngularSpeed / spin.decelDuration) or 0
    end

    return spin
end

local function PrepareCenterSpin(spin)
    if spin == nil then
        return
    end

    spin.centerPosition = spin.orbitPointRef ~= nil and spin.orbitPointRef.position or spin.baseWorldPosition
    spin.baseOffsetX = spin.baseWorldPosition.x - spin.centerPosition.x
    spin.baseOffsetY = spin.baseWorldPosition.y - spin.centerPosition.y
    spin.baseOffsetZ = spin.baseWorldPosition.z - spin.centerPosition.z
    spin.transform.position = spin.baseWorldPosition
    spin.transform.rotation = spin.baseWorldRotation
    spin.elapsed = 0
    spin.currentAngle = 0
end

local function ResetCenterSpin(spin)
    if spin == nil then
        return
    end

    spin.transform.position = spin.baseWorldPosition
    spin.transform.rotation = spin.baseWorldRotation
    spin.elapsed = 0
    spin.currentAngle = 0
end

local function GetCenterSpinAngle(spin, time)
    if spin == nil then
        return 0
    end

    if time <= 0 then
        return 0
    end

    if spin.totalDuration <= 0.0001 or spin.totalAngle <= 0.0001 then
        return spin.totalAngle
    end

    local angle = 0
    local t = time

    if spin.accelDuration > 0 then
        if t < spin.accelDuration then
            return 0.5 * spin.accelRate * t * t
        end
        angle = angle + 0.5 * spin.maxAngularSpeed * spin.accelDuration
        t = t - spin.accelDuration
    end

    if spin.cruiseDuration > 0 then
        if t < spin.cruiseDuration then
            return angle + spin.maxAngularSpeed * t
        end
        angle = angle + spin.maxAngularSpeed * spin.cruiseDuration
        t = t - spin.cruiseDuration
    end

    if spin.decelDuration > 0 then
        if t < spin.decelDuration then
            return angle + spin.maxAngularSpeed * t - 0.5 * spin.decelRate * t * t
        end
    end

    return spin.totalAngle
end

local function GetCenterSpinSpeedFactor(spin, time)
    local minFactor = Clamp01(GearMinSpeedFactor, 0.1)
    if spin == nil or spin.maxAngularSpeed <= 0.0001 or spin.totalDuration <= 0.0001 then
        return minFactor
    end

    if time <= 0 then
        return minFactor
    end

    local t = time

    if spin.accelDuration > 0 then
        if t < spin.accelDuration then
            local normalized = t / spin.accelDuration
            return minFactor + (1 - minFactor) * normalized
        end
        t = t - spin.accelDuration
    end

    if spin.cruiseDuration > 0 then
        if t < spin.cruiseDuration then
            return 1
        end
        t = t - spin.cruiseDuration
    end

    if spin.decelDuration > 0 then
        if t < spin.decelDuration then
            local normalized = 1 - (t / spin.decelDuration)
            return minFactor + (1 - minFactor) * normalized
        end
    end

    return minFactor
end

local function ApplyCenterOrbit(spin, angle)
    local deltaAngle = angle - spin.currentAngle
    local radians = angle * math.pi / 180
    local cosValue = math.cos(radians)
    local sinValue = math.sin(radians)

    local rotatedX = spin.baseOffsetX * cosValue + spin.baseOffsetZ * sinValue
    local rotatedZ = -spin.baseOffsetX * sinValue + spin.baseOffsetZ * cosValue

    spin.transform.position = CS.UnityEngine.Vector3(
        spin.centerPosition.x + rotatedX,
        spin.centerPosition.y + spin.baseOffsetY,
        spin.centerPosition.z + rotatedZ
    )
    spin.transform:Rotate(CS.UnityEngine.Vector3.up, deltaAngle, CS.UnityEngine.Space.World)
    spin.currentAngle = angle
end

local GetActiveSkyMaterial
local ApplySkyPulseStateToKnownMaterials

local function ResetOrbitPulseEffects()
    orbitPulseActive = false
    orbitPulseElapsed = 0
    orbitPulseDuration = 0

    local activeSkyMaterial = GetActiveSkyMaterial()
    if activeSkyMaterial ~= nil then
        cachedSkyMaterials[currentEnvironmentIndex] = activeSkyMaterial
        ApplySkyPulseStateToKnownMaterials(activeSkyMaterial:GetFloat("_ReverseBlend"), 0)
        return
    end
end

local function ResetOrbitPulseCycleState()
    orbitPulseCompleted = false
    orbitPulseTargetReverseBlend = nil
    ResetOrbitPulseEffects()
end

local function ChangeEnvironmentByIndex(envIndex, duration)
    -- Debug: temporarily disable environment switching to verify whether
    -- the issue comes from Change() swapping to another sky material instance.
    return false
end

GetActiveSkyMaterial = function()
    if SceneEnvironment == nil then
        if not loggedSkyMaterialAccessFailure then
            print("[DouyinSequenceController] skyMaterial unavailable: SceneEnvironment instance is nil")
            loggedSkyMaterialAccessFailure = true
        end
        return nil
    end

    local ok, material = pcall(function()
        return SceneEnvironment.settings.skyMaterial
    end)
    if not ok then
        if not loggedSkyMaterialAccessFailure then
            print("[DouyinSequenceController] SceneEnvironment.settings.skyMaterial access failed: " .. tostring(material))
            loggedSkyMaterialAccessFailure = true
        end
        return nil
    end

    if material ~= nil then
        loggedSkyMaterialAccessFailure = false
        loggedSkyMaterialNil = false
        return material
    end

    if not loggedSkyMaterialNil then
        print("[DouyinSequenceController] skyMaterial is nil for envIndex=" .. tostring(currentEnvironmentIndex))
        loggedSkyMaterialNil = true
    end
    return nil
end

local function CopySkyPulseState(sourceMaterial, targetMaterial)
    if sourceMaterial == nil or targetMaterial == nil then
        return
    end

    local reverseBlend = sourceMaterial:GetFloat("_ReverseBlend")
    local pulseProgress = sourceMaterial:GetFloat("_PulseProgress")
    targetMaterial:SetFloat("_ReverseBlend", reverseBlend)
    targetMaterial:SetFloat("_PulseProgress", pulseProgress)
end

ApplySkyPulseStateToKnownMaterials = function(reverseBlend, pulseProgress)
    local activeMaterial = GetActiveSkyMaterial()
    if activeMaterial ~= nil then
        activeMaterial:SetFloat("_ReverseBlend", reverseBlend)
        activeMaterial:SetFloat("_PulseProgress", pulseProgress)
    end
end

local function CompletePendingEnvironmentTransition()
    if pendingEnvironmentIndex == nil then
        return
    end

    local sourceMaterial = pendingSourceMaterial or cachedSkyMaterials[pendingSourceEnvironmentIndex]
    local targetMaterial = GetActiveSkyMaterial()

    if targetMaterial ~= nil then
        cachedSkyMaterials[pendingEnvironmentIndex] = targetMaterial
        CopySkyPulseState(sourceMaterial, targetMaterial)
    elseif cachedSkyMaterials[pendingEnvironmentIndex] ~= nil then
        CopySkyPulseState(sourceMaterial, cachedSkyMaterials[pendingEnvironmentIndex])
    end

    currentEnvironmentIndex = pendingEnvironmentIndex
    pendingEnvironmentIndex = nil
    pendingEnvironmentTimer = 0
    pendingSourceEnvironmentIndex = nil
    pendingSourceMaterial = nil
end

local function UpdatePendingEnvironmentTransition(deltaTime)
    if pendingEnvironmentIndex == nil then
        return
    end

    local sourceMaterial = pendingSourceMaterial or cachedSkyMaterials[pendingSourceEnvironmentIndex]
    local cachedTargetMaterial = cachedSkyMaterials[pendingEnvironmentIndex]
    if sourceMaterial ~= nil and cachedTargetMaterial ~= nil then
        CopySkyPulseState(sourceMaterial, cachedTargetMaterial)
    end

    local liveSkyMaterial = GetActiveSkyMaterial()
    if liveSkyMaterial ~= nil and liveSkyMaterial ~= sourceMaterial then
        cachedSkyMaterials[pendingEnvironmentIndex] = liveSkyMaterial
        CopySkyPulseState(sourceMaterial, liveSkyMaterial)
        currentEnvironmentIndex = pendingEnvironmentIndex
        pendingEnvironmentIndex = nil
        pendingEnvironmentTimer = 0
        pendingSourceEnvironmentIndex = nil
        pendingSourceMaterial = nil
        return
    end

    pendingEnvironmentTimer = pendingEnvironmentTimer - deltaTime
    if pendingEnvironmentTimer <= 0 then
        CompletePendingEnvironmentTransition()
    end
end

local function SyncEnvironmentWithSkyboxTransition(duration)
    if pendingEnvironmentIndex ~= nil then
        return
    end

    local sourceMaterial = GetActiveSkyMaterial()
    if sourceMaterial == nil then
        return
    end

    cachedSkyMaterials[currentEnvironmentIndex] = sourceMaterial

    local reverseBlend = sourceMaterial:GetFloat("_ReverseBlend")
    local targetEnvIndex = reverseBlend > 0.5 and 0 or 1

    local changed = ChangeEnvironmentByIndex(targetEnvIndex, duration)
    if not changed then
        return
    end

    pendingEnvironmentIndex = targetEnvIndex
    pendingEnvironmentTimer = ClampNonNegative(duration, 0)
    pendingSourceEnvironmentIndex = currentEnvironmentIndex
    pendingSourceMaterial = sourceMaterial

    if cachedSkyMaterials[targetEnvIndex] ~= nil then
        CopySkyPulseState(sourceMaterial, cachedSkyMaterials[targetEnvIndex])
    end

    if pendingEnvironmentTimer <= 0 then
        CompletePendingEnvironmentTransition()
    end
end

local function StartOrbitPulseCycle(spin)
    if orbitPulseCompleted then
        return
    end

    orbitPulseActive = true
    orbitPulseElapsed = 0
    orbitPulseDuration = math.max(spin.totalDuration, 0.01)

    SyncEnvironmentWithSkyboxTransition(orbitPulseDuration)

    local skyMaterial = GetActiveSkyMaterial()
    if skyMaterial ~= nil then
        if orbitPulseCycleCount > 0 then
            local currentReverseBlend = skyMaterial:GetFloat("_ReverseBlend")
            orbitPulseTargetReverseBlend = currentReverseBlend > 0.5 and 0 or 1
            ApplySkyPulseStateToKnownMaterials(orbitPulseTargetReverseBlend, 0)
        else
            orbitPulseTargetReverseBlend = skyMaterial:GetFloat("_ReverseBlend")
        end
    end

    if OrbitPulseParticle ~= nil then
        if OrbitPulseParticle.isPlaying then
            OrbitPulseParticle:Stop()
            OrbitPulseParticle:Clear()
        end
        OrbitPulseParticle:Play()
    end
end

local function CompleteOrbitPulseCycle()
    orbitPulseActive = false
    orbitPulseElapsed = orbitPulseDuration
    orbitPulseCompleted = true
    orbitPulseCycleCount = orbitPulseCycleCount + 1
end

local function ToggleOrbitReverseBlend()
    local skyMaterial = GetActiveSkyMaterial()
    if skyMaterial == nil then
        return
    end

    local currentValue = skyMaterial:GetFloat("_ReverseBlend")
    local nextValue = currentValue > 0.5 and 0 or 1
    skyMaterial:SetFloat("_ReverseBlend", nextValue)
end

local function UpdateOrbitPulseEffects(spin, deltaTime)
    if spin == nil or spin.totalDuration <= 0 then
        ResetOrbitPulseEffects()
        return
    end

    if orbitPulseCompleted then
        return
    end

    if not orbitPulseActive then
        StartOrbitPulseCycle(spin)
    end

    orbitPulseElapsed = orbitPulseElapsed + deltaTime
    local progress = math.min(orbitPulseElapsed / orbitPulseDuration, 1)

    local skyMaterial = GetActiveSkyMaterial()
    if skyMaterial ~= nil then
        local reverseBlend = orbitPulseTargetReverseBlend
        if reverseBlend == nil then
            reverseBlend = skyMaterial:GetFloat("_ReverseBlend")
            orbitPulseTargetReverseBlend = reverseBlend
        end
        ApplySkyPulseStateToKnownMaterials(reverseBlend, progress)
    end

    if progress >= 1 then
        CompleteOrbitPulseCycle()
    end
end

local function UpdateCenterSpin(spin, deltaTime)
    if spin == nil then
        return true
    end

    if spin.totalDuration <= 0.0001 or spin.totalAngle <= 0.0001 then
        ResetCenterSpin(spin)
        return true
    end

    spin.elapsed = spin.elapsed + deltaTime
    if spin.elapsed >= spin.totalDuration then
        ResetCenterSpin(spin)
        return true
    end

    ApplyCenterOrbit(spin, GetCenterSpinAngle(spin, spin.elapsed))
    return false
end

local function EnterState(state)
    currentState = state
end

local function EnterWaitState(duration, nextState)
    waitTimer = ClampNonNegative(duration, 0)
    waitNextState = nextState or STATE_IDLE

    if waitTimer <= 0 then
        EnterState(waitNextState)
        return
    end

    EnterState(STATE_WAIT)
end

local function AddIfNotNil(list, item)
    if item ~= nil then
        table.insert(list, item)
    end
end

local function SetupControllers()
    pendulums = {}
    AddIfNotNil(pendulums, MakePendulum(PendulumA, PendulumAxisA, PendulumUseLocalA, PendulumMaxAngleA, PendulumSpeedA, PendulumStartPhaseA, PendulumStopAngleA))
    AddIfNotNil(pendulums, MakePendulum(PendulumB, PendulumAxisB, PendulumUseLocalB, PendulumMaxAngleB, PendulumSpeedB, PendulumStartPhaseB, PendulumStopAngleB))

    extenders = {}
    AddIfNotNil(extenders, MakeExtender(ExtenderA, ExtendAxisA, ExtendUseLocalA, ExtendDistanceA, ExtendSpeedA))
    AddIfNotNil(extenders, MakeExtender(ExtenderB, ExtendAxisB, ExtendUseLocalB, ExtendDistanceB, ExtendSpeedB))

    balls = {}
    AddIfNotNil(balls, MakeMechanicalRotator(BallA, BallAxisA, BallUseLocalA, BallRotateAngleA, BallRotateSpeedA))
    AddIfNotNil(balls, MakeMechanicalRotator(BallB, BallAxisB, BallUseLocalB, BallRotateAngleB, BallRotateSpeedB))

    centerSpins = {}
    AddIfNotNil(centerSpins, BuildCenterSpin(CenterTransform, CenterOrbitPoint, CenterUseLocalSpace, CenterSpinLoops, CenterAccelDuration, CenterCruiseDuration, CenterDecelDuration))
    AddIfNotNil(centerSpins, BuildCenterSpin(CenterTransformB, CenterOrbitPointB, CenterUseLocalSpace, CenterSpinLoops, CenterAccelDuration, CenterCruiseDuration, CenterDecelDuration))
    AddIfNotNil(centerSpins, BuildCenterSpin(CenterTransformC, CenterOrbitPointC, CenterUseLocalSpace, CenterSpinLoops, CenterAccelDuration, CenterCruiseDuration, CenterDecelDuration))
    AddIfNotNil(centerSpins, BuildCenterSpin(CenterTransformD, CenterOrbitPointD, CenterUseLocalSpace, CenterSpinLoops, CenterAccelDuration, CenterCruiseDuration, CenterDecelDuration))

    gears = {}
    AddIfNotNil(gears, MakeGear(GearTransform1, GearAxis1, GearSpeed1))
    AddIfNotNil(gears, MakeGear(GearTransform2, GearAxis2, GearSpeed2))
    AddIfNotNil(gears, MakeGear(GearTransform3, GearAxis3, GearSpeed3))
    AddIfNotNil(gears, MakeGear(GearTransform4, GearAxis4, GearSpeed4))
    AddIfNotNil(gears, MakeGear(GearTransform5, GearAxis5, GearSpeed5))
    AddIfNotNil(gears, MakeGear(GearTransform6, GearAxis6, GearSpeed6))
    AddIfNotNil(gears, MakeGear(GearTransform7, GearAxis7, GearSpeed7))
    AddIfNotNil(gears, MakeGear(GearTransform8, GearAxis8, GearSpeed8))
    AddIfNotNil(gears, MakeGear(GearTransform9, GearAxis9, GearSpeed9))
    AddIfNotNil(gears, MakeGear(GearTransform10, GearAxis10, GearSpeed10))
    AddIfNotNil(gears, MakeGear(GearTransform11, GearAxis11, GearSpeed11))
    AddIfNotNil(gears, MakeGear(GearTransform12, GearAxis12, GearSpeed12))
    AddIfNotNil(gears, MakeGear(GearTransform13, GearAxis13, GearSpeed13))
    AddIfNotNil(gears, MakeGear(GearTransform14, GearAxis14, GearSpeed14))
    AddIfNotNil(gears, MakeGear(GearTransform15, GearAxis15, GearSpeed15))
    AddIfNotNil(gears, MakeGear(GearTransform16, GearAxis16, GearSpeed16))
end

local function ResetAllToBase()
    pendingEnvironmentIndex = nil
    pendingEnvironmentTimer = 0
    pendingSourceEnvironmentIndex = nil
    pendingSourceMaterial = nil
    orbitPulseCompleted = false
    orbitPulseCycleCount = 0

    for i = 1, #pendulums do
        ResetPendulum(pendulums[i])
    end
    for i = 1, #extenders do
        ResetExtender(extenders[i])
    end
    for i = 1, #balls do
        ResetMechanicalRotator(balls[i])
    end
    for i = 1, #centerSpins do
        ResetCenterSpin(centerSpins[i])
    end
    for i = 1, #gears do
        ResetGear(gears[i])
    end
    ResetOrbitPulseEffects()
end

local function StartPendulumState()
    for i = 1, #pendulums do
        ResetPendulum(pendulums[i])
    end
    waitTimer = 0
    waitNextState = STATE_IDLE
    EnterState(STATE_PENDULUM)
end

function Awake()
    if AutoPlay == nil then
        AutoPlay = true
    end
    if LoopSequence == nil then
        LoopSequence = true
    end
    if PendulumSwingCount == nil or PendulumSwingCount < 1 then
        PendulumSwingCount = 17
    end

    SetupControllers()
    ResetAllToBase()

    isPlaying = AutoPlay
    if isPlaying then
        StartPendulumState()
    else
        EnterState(STATE_IDLE)
    end
end

function Update()
    if not isPlaying then
        return
    end

    local deltaTime = CS.UnityEngine.Time.deltaTime
    UpdatePendingEnvironmentTransition(deltaTime)

    local gearSpeedFactor = Clamp01(GearMinSpeedFactor, 0.1)
    if currentState == STATE_CENTER_SPIN and #centerSpins > 0 then
        gearSpeedFactor = GetCenterSpinSpeedFactor(centerSpins[1], centerSpins[1].elapsed)
    end

    for i = 1, #gears do
        UpdateGear(gears[i], deltaTime, gearSpeedFactor)
    end

    if currentState == STATE_WAIT then
        waitTimer = waitTimer - deltaTime
        if waitTimer <= 0 then
            waitTimer = 0
            if waitNextState == STATE_PENDULUM then
                StartPendulumState()
            else
                EnterState(waitNextState)
            end
        end
        return
    end

    if currentState == STATE_PENDULUM then
        local allCompleted = true
        for i = 1, #pendulums do
            if not UpdatePendulum(pendulums[i], deltaTime) then
                allCompleted = false
            end
        end

        if allCompleted then
            for i = 1, #pendulums do
                StopPendulumAtAngle(pendulums[i])
            end
            EnterWaitState(DelayAfterPendulum, STATE_EXTEND)
        end
        return
    end

    if currentState == STATE_EXTEND then
        local allCompleted = true
        for i = 1, #extenders do
            if not UpdateExtender(extenders[i], deltaTime, 1) then
                allCompleted = false
            end
        end

        if allCompleted then
            EnterWaitState(DelayAfterExtend, STATE_BALL_ROTATE)
        end
        return
    end

    if currentState == STATE_BALL_ROTATE then
        local allCompleted = true
        for i = 1, #balls do
            if not UpdateMechanicalRotator(balls[i], deltaTime, 1) then
                allCompleted = false
            end
        end

        if allCompleted then
            for i = 1, #centerSpins do
                PrepareCenterSpin(centerSpins[i])
            end
            ResetOrbitPulseCycleState()
            EnterWaitState(DelayAfterBallRotate, STATE_CENTER_SPIN)
        end
        return
    end

    if currentState == STATE_CENTER_SPIN then
        local allCompleted = true
        for i = 1, #centerSpins do
            if not UpdateCenterSpin(centerSpins[i], deltaTime) then
                allCompleted = false
            end
        end
        if not allCompleted then
            UpdateOrbitPulseEffects(centerSpins[1], deltaTime)
        end

        if allCompleted then
            EnterWaitState(DelayAfterCenterSpin, STATE_BALL_RESET)
        end
        return
    end

    if currentState == STATE_BALL_RESET then
        local allCompleted = true
        for i = 1, #balls do
            if not UpdateMechanicalRotator(balls[i], deltaTime, -1) then
                allCompleted = false
            end
        end

        if allCompleted then
            EnterWaitState(DelayAfterBallReset, STATE_RETRACT)
        end
        return
    end

    if currentState == STATE_RETRACT then
        local allCompleted = true
        for i = 1, #extenders do
            if not UpdateExtender(extenders[i], deltaTime, -1) then
                allCompleted = false
            end
        end

        if allCompleted then
            if LoopSequence then
                EnterWaitState(DelayAfterRetract, STATE_PENDULUM)
            else
                EnterState(STATE_IDLE)
                isPlaying = false
            end
        end
    end
end

function PlaySequence()
    if #pendulums == 0 and #extenders == 0 and #balls == 0 and #centerSpins == 0 then
        SetupControllers()
        ResetAllToBase()
    end

    if currentState == STATE_IDLE then
        StartPendulumState()
    end
    isPlaying = true
end

function PauseSequence()
    isPlaying = false
end

function ResumeSequence()
    isPlaying = true
end

function RestartSequence()
    SetupControllers()
    ResetAllToBase()
    isPlaying = true
    StartPendulumState()
end

function StopSequence()
    isPlaying = false
    waitTimer = 0
    waitNextState = STATE_IDLE
    ResetAllToBase()
    EnterState(STATE_IDLE)
end

function GetCurrentState()
    return currentState
end











