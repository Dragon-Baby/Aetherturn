using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceRegistry : MonoBehaviour
{
    public DouyinSequencePendulumGroup PendulumGroup;
    public DouyinSequenceMoveGroup ExtendGroup;
    public DouyinSequenceRotateGroup BallGroup;
    public DouyinSequenceOrbitGroup OrbitGroup;
    public DouyinSequenceGearGroup GearGroup;
    public DouyinSequenceFxBridge FxBridge;
    public DouyinVertexLightManager VertexLightManager;
    public DouyinSequenceAudioBridge AudioBridge;
    public bool EnableValidationLog = true;

    public bool Validate()
    {
        bool ok = true;
        ok = ValidateReference(PendulumGroup, "PendulumGroup") && ok;
        ok = ValidateReference(ExtendGroup, "ExtendGroup") && ok;
        ok = ValidateReference(BallGroup, "BallGroup") && ok;
        ok = ValidateReference(OrbitGroup, "OrbitGroup") && ok;
        ok = ValidateReference(GearGroup, "GearGroup") && ok;
        if (FxBridge != null) ok = ValidateReference(FxBridge, "FxBridge") && ok;
        if (VertexLightManager != null) ok = ValidateReference(VertexLightManager, "VertexLightManager") && ok;
        if (AudioBridge != null) ok = ValidateReference(AudioBridge, "AudioBridge") && ok;
        return ok;
    }

    public void CollectAll()
    {
        PendulumGroup?.CollectUnits();
        ExtendGroup?.CollectUnits();
        BallGroup?.CollectUnits();
        OrbitGroup?.CollectUnits();
        GearGroup?.CollectUnits();
        VertexLightManager?.CollectLights();
    }

    public void ResetAllToBase()
    {
        PendulumGroup?.ResetToBase();
        ExtendGroup?.ResetToBase();
        BallGroup?.ResetToBase();
        OrbitGroup?.ResetToBase();
        GearGroup?.ResetToBase();
        FxBridge?.ResetToBase();
        VertexLightManager?.ResetToBase();
        AudioBridge?.ResetToBase();
    }

    public void BeginPendulums() => PendulumGroup?.BeginForward();
    public void TickPendulums(float deltaTime) => PendulumGroup?.Tick(deltaTime);
    public bool ArePendulumsComplete() => PendulumGroup == null || PendulumGroup.IsComplete();
    public void BeginExtendForward() => ExtendGroup?.BeginForward();
    public void BeginExtendBackward() => ExtendGroup?.BeginBackward();
    public void TickExtenders(float deltaTime) => ExtendGroup?.Tick(deltaTime);
    public bool AreExtendersComplete() => ExtendGroup == null || ExtendGroup.IsComplete();
    public void BeginBallForward() => BallGroup?.BeginForward();
    public void BeginBallBackward() => BallGroup?.BeginBackward();
    public void TickBalls(float deltaTime) => BallGroup?.Tick(deltaTime);
    public bool AreBallsComplete() => BallGroup == null || BallGroup.IsComplete();
    public void BeginOrbit() => OrbitGroup?.BeginForward();
    public void TickOrbit(float deltaTime) => OrbitGroup?.Tick(deltaTime);
    public bool IsOrbitComplete() => OrbitGroup == null || OrbitGroup.IsComplete();
    public float GetOrbitSpeedFactor() => OrbitGroup != null ? OrbitGroup.GetSpeedFactor() : 0f;
    public float GetOrbitProgress01() => OrbitGroup != null ? OrbitGroup.GetProgress01() : 0f;
    public float GetOrbitDuration() => OrbitGroup != null ? OrbitGroup.GetTotalDuration() : 0f;
    public void TickGears(float deltaTime, float? driveFactor) => GearGroup?.Tick(deltaTime, driveFactor);
    public void BeginOrbitFx(float totalDuration) => FxBridge?.BeginOrbitFx(totalDuration);
    public void TickOrbitFx(float deltaTime, float progress01) => FxBridge?.TickOrbitFx(deltaTime, progress01);
    public void CompleteOrbitFx() => FxBridge?.CompleteOrbitFx();
    public float GetOrbitNightBlend01(float progress01) => FxBridge != null ? FxBridge.GetOrbitNightBlend01(progress01) : 0f;
    public float GetCurrentNightBlend01() => FxBridge != null ? FxBridge.GetCurrentNightBlend01() : 0f;
    public void TickVertexLights(float deltaTime) => VertexLightManager?.Tick(deltaTime);
    public void ApplyVertexLights() => VertexLightManager?.ApplyGlobals();
    public void SetVertexLightIntensity(int lightIndex, float intensity) => VertexLightManager?.SetLightIntensity(lightIndex, intensity);
    public void SetVertexLightIntensityScale(int lightIndex, float scale) => VertexLightManager?.SetLightIntensityScale(lightIndex, scale);
    public void FadeVertexLightIntensity(int lightIndex, float targetIntensity, float duration) => VertexLightManager?.FadeLightIntensity(lightIndex, targetIntensity, duration);
    public void FadeVertexLightIntensityScale(int lightIndex, float targetScale, float duration) => VertexLightManager?.FadeLightIntensityScale(lightIndex, targetScale, duration);
    public void SetAllVertexLightIntensityScale(float scale) => VertexLightManager?.SetAllIntensityScale(scale);
    public void FadeAllVertexLightIntensityScale(float targetScale, float duration) => VertexLightManager?.FadeAllIntensityScale(targetScale, duration);
    public void BeginSequenceAudio(string stateName) => AudioBridge?.BeginState(stateName);
    public void TickSequenceAudio(float deltaTime) => AudioBridge?.Tick(deltaTime);
    public void PauseSequenceAudio() => AudioBridge?.PauseAll();
    public void ResumeSequenceAudio() => AudioBridge?.ResumeActive();
    public void StopSequenceAudio() => AudioBridge?.StopAll();

    private bool ValidateReference(UnityEngine.Object target, string label)
    {
        if (target != null)
        {
            return true;
        }

        if (EnableValidationLog)
        {
            Debug.Log("[DouyinSequenceRegistry] " + label + " is nil", this);
        }
        return false;
    }
}

