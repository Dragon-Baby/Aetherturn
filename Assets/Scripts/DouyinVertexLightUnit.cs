using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinVertexLightUnit : MonoBehaviour
{
    public float Radius = 4f;
    public UnityEngine.Color Color = UnityEngine.Color.white;
    public float Intensity = 1f;
    public float InitialIntensity = 1f;
    public DouyinVertexLightManager Manager;
    public bool AutoRegister = true;
    public bool DisableUnityLight = true;
    public bool EnableDebugLog;

    private float baseIntensity = 1f;
    private float currentIntensity = 1f;
    private float fadeStartIntensity = 1f;
    private float fadeTargetIntensity = 1f;
    private float fadeDuration;
    private float fadeElapsed;
    private bool isFading;
    private bool hasInitialized;

    private void Awake()
    {
        EnsureInitialized();
        if (AutoRegister && Manager != null)
        {
            Manager.RegisterLight(this);
        }
    }

    private void OnDestroy()
    {
        if (Manager != null)
        {
            Manager.UnregisterLight(this);
        }
    }

    public void ResetToBase()
    {
        EnsureInitialized();
        currentIntensity = baseIntensity;
        Intensity = currentIntensity;
        isFading = false;
        fadeElapsed = 0f;
    }

    public void Tick(float deltaTime)
    {
        EnsureInitialized();
        ApplyUnityLightState();

        if (!isFading)
        {
            currentIntensity = Mathf.Max(0f, Intensity);
            return;
        }

        if (fadeDuration <= 0f)
        {
            currentIntensity = fadeTargetIntensity;
            Intensity = currentIntensity;
            isFading = false;
            return;
        }

        fadeElapsed += deltaTime;
        float t = Mathf.Clamp01(fadeElapsed / fadeDuration);
        currentIntensity = Mathf.Lerp(fadeStartIntensity, fadeTargetIntensity, t);
        Intensity = currentIntensity;

        if (t >= 1f)
        {
            isFading = false;
        }
    }

    public void SetIntensity(float value)
    {
        EnsureInitialized();
        currentIntensity = Mathf.Max(0f, value);
        Intensity = currentIntensity;
        isFading = false;
    }

    public void SetIntensityScale(float scale)
    {
        EnsureInitialized();
        SetIntensity(baseIntensity * Mathf.Max(0f, scale));
    }

    public void FadeIntensity(float targetIntensity, float duration)
    {
        EnsureInitialized();
        fadeStartIntensity = currentIntensity;
        fadeTargetIntensity = Mathf.Max(0f, targetIntensity);
        fadeDuration = Mathf.Max(0f, duration);
        fadeElapsed = 0f;
        isFading = true;

        if (fadeDuration <= 0f)
        {
            SetIntensity(fadeTargetIntensity);
        }
    }

    public void FadeIntensityScale(float targetScale, float duration)
    {
        EnsureInitialized();
        FadeIntensity(baseIntensity * Mathf.Max(0f, targetScale), duration);
    }

    public void SetRadius(float value)
    {
        Radius = Mathf.Max(0f, value);
    }

    public void SetColor(UnityEngine.Color value)
    {
        Color = value;
    }

    public Vector3 GetPosition() => transform.position;
    public float GetRadius()
    {
        EnsureInitialized();
        return Radius;
    }

    public UnityEngine.Color GetColor() => Color;

    public float GetIntensity()
    {
        EnsureInitialized();
        return currentIntensity;
    }

    public bool IsActive()
    {
        EnsureInitialized();
        return Radius > 0f && currentIntensity > 0f;
    }

    public bool IsFading() => isFading;

    private void EnsureInitialized()
    {
        Radius = Mathf.Max(0f, Radius);
        Intensity = Mathf.Max(0f, Intensity);
        InitialIntensity = Mathf.Max(0f, InitialIntensity);
        if (!hasInitialized)
        {
            baseIntensity = InitialIntensity;
            currentIntensity = InitialIntensity;
            Intensity = currentIntensity;
        }

        ApplyUnityLightState();
        hasInitialized = true;
    }

    private void ApplyUnityLightState()
    {
        if (!DisableUnityLight)
        {
            return;
        }

        Light light = GetComponent<Light>();
        if (light != null)
        {
            light.enabled = false;
        }
    }
}

