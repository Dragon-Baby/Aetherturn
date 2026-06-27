using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinVertexLightManager : MonoBehaviour
{
    private const int DefaultMaxLightCount = 8;

    public GameObject[] LightObjects;
    public string LightScriptName = "DouyinVertexLightUnit";
    public int MaxLightCount = 8;
    public float GlobalIntensityScale = 1f;
    public bool AutoCollectOnAwake = true;
    public bool EnableDebugLog;

    private readonly List<DouyinVertexLightUnit> lights = new List<DouyinVertexLightUnit>();
    private Vector4[] positionRadiusArray;
    private Vector4[] colorIntensityArray;

    private void Awake()
    {
        EnsureArrays();
        if (AutoCollectOnAwake)
        {
            CollectLights();
        }
        ApplyGlobals();
    }

    public void CollectLights()
    {
        lights.Clear();

        if (string.IsNullOrEmpty(LightScriptName))
        {
            LightScriptName = "DouyinVertexLightUnit";
        }

        if (LightObjects != null)
        {
            for (int i = 0; i < LightObjects.Length; i++)
            {
                CollectFromObject(LightObjects[i]);
            }
        }

        Log("Collected vertex lights: " + lights.Count);
    }

    public void RegisterLight(DouyinVertexLightUnit target)
    {
        if (target == null || lights.Contains(target))
        {
            return;
        }

        lights.Add(target);
        ApplyGlobals();
    }

    public void UnregisterLight(DouyinVertexLightUnit target)
    {
        if (target == null)
        {
            return;
        }

        lights.Remove(target);
        ApplyGlobals();
    }

    public void ResetToBase()
    {
        for (int i = 0; i < lights.Count; i++)
        {
            lights[i].ResetToBase();
        }
        ApplyGlobals();
    }

    public void Tick(float deltaTime)
    {
        for (int i = 0; i < lights.Count; i++)
        {
            lights[i].Tick(deltaTime);
        }
        ApplyGlobals();
    }

    public void ApplyGlobals()
    {
        EnsureArrays();

        int maxCount = ResolveMaxLightCount();
        int activeCount = 0;
        float scale = Mathf.Max(0f, GlobalIntensityScale);

        for (int i = 0; i < maxCount; i++)
        {
            positionRadiusArray[i] = Vector4.zero;
            colorIntensityArray[i] = Vector4.zero;
        }

        for (int i = 0; i < lights.Count && activeCount < maxCount; i++)
        {
            DouyinVertexLightUnit light = lights[i];
            if (light == null || !light.IsActive())
            {
                continue;
            }

            Vector3 position = light.GetPosition();
            Color color = light.GetColor();
            positionRadiusArray[activeCount] = new Vector4(position.x, position.y, position.z, light.GetRadius());
            colorIntensityArray[activeCount] = new Vector4(color.r, color.g, color.b, light.GetIntensity() * scale);
            activeCount++;
        }

        Shader.SetGlobalInt("_AetherVertexLightCount", activeCount);
        Shader.SetGlobalVectorArray("_AetherVertexLightPositionRadius", positionRadiusArray);
        Shader.SetGlobalVectorArray("_AetherVertexLightColorIntensity", colorIntensityArray);
    }

    public int GetLightCount() => lights.Count;

    public void SetGlobalIntensityScale(float scale)
    {
        GlobalIntensityScale = Mathf.Max(0f, scale);
        ApplyGlobals();
    }

    public void SetLightIntensity(int lightIndex, float intensity)
    {
        DouyinVertexLightUnit target = GetLightByLuaStyleIndex(lightIndex);
        if (target == null)
        {
            return;
        }
        target.SetIntensity(intensity);
        ApplyGlobals();
    }

    public void SetLightIntensityScale(int lightIndex, float scale)
    {
        DouyinVertexLightUnit target = GetLightByLuaStyleIndex(lightIndex);
        if (target == null)
        {
            return;
        }
        target.SetIntensityScale(scale);
        ApplyGlobals();
    }

    public void FadeLightIntensity(int lightIndex, float targetIntensity, float duration)
    {
        GetLightByLuaStyleIndex(lightIndex)?.FadeIntensity(targetIntensity, duration);
    }

    public void FadeLightIntensityScale(int lightIndex, float targetScale, float duration)
    {
        GetLightByLuaStyleIndex(lightIndex)?.FadeIntensityScale(targetScale, duration);
    }

    public void SetAllIntensityScale(float scale)
    {
        for (int i = 0; i < lights.Count; i++)
        {
            lights[i].SetIntensityScale(scale);
        }
        ApplyGlobals();
    }

    public void FadeAllIntensityScale(float targetScale, float duration)
    {
        for (int i = 0; i < lights.Count; i++)
        {
            lights[i].FadeIntensityScale(targetScale, duration);
        }
    }

    public void ClearLights()
    {
        lights.Clear();
        ClearGlobalArrays();
    }

    private void CollectFromObject(GameObject source)
    {
        if (source == null)
        {
            return;
        }

        DouyinVertexLightUnit light = null;
        if (!string.IsNullOrEmpty(LightScriptName))
        {
            MonoBehaviour[] behaviours = source.GetComponents<MonoBehaviour>();
            for (int i = 0; i < behaviours.Length; i++)
            {
                if (behaviours[i] is DouyinVertexLightUnit unit && behaviours[i].GetType().Name == LightScriptName)
                {
                    light = unit;
                    break;
                }
            }
        }

        if (light == null)
        {
            light = source.GetComponent<DouyinVertexLightUnit>();
        }

        if (light != null && !lights.Contains(light))
        {
            lights.Add(light);
        }
    }

    private DouyinVertexLightUnit GetLightByLuaStyleIndex(int lightIndex)
    {
        int index = lightIndex - 1;
        return index >= 0 && index < lights.Count ? lights[index] : null;
    }

    private int ResolveMaxLightCount()
    {
        MaxLightCount = Mathf.Clamp(MaxLightCount, 1, DefaultMaxLightCount);
        return MaxLightCount;
    }

    private void EnsureArrays()
    {
        int maxCount = ResolveMaxLightCount();
        if (positionRadiusArray != null && positionRadiusArray.Length == maxCount)
        {
            return;
        }

        positionRadiusArray = new Vector4[maxCount];
        colorIntensityArray = new Vector4[maxCount];
    }

    private void ClearGlobalArrays()
    {
        EnsureArrays();
        for (int i = 0; i < positionRadiusArray.Length; i++)
        {
            positionRadiusArray[i] = Vector4.zero;
            colorIntensityArray[i] = Vector4.zero;
        }
        Shader.SetGlobalInt("_AetherVertexLightCount", 0);
        Shader.SetGlobalVectorArray("_AetherVertexLightPositionRadius", positionRadiusArray);
        Shader.SetGlobalVectorArray("_AetherVertexLightColorIntensity", colorIntensityArray);
    }

    private void Log(string message)
    {
        if (EnableDebugLog)
        {
            Debug.Log("[DouyinVertexLightManager] " + message, this);
        }
    }
}

