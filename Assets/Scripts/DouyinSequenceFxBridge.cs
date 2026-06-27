using UnityEngine;

public sealed class DouyinSequenceFxBridge : MonoBehaviour
{
    public Material SkyMaterial;
    public Light DirectionalLight;
    public ParticleSystem OrbitPulseParticle;
    public AudioSource OrbitPulseAudio;
    public GameObject OrbitPulseAudioObject;
    public bool EnableOrbitPulseAudio = true;
    public float OrbitPulseAudioVolume = 1f;
    public bool EnableEnvironmentSwitch;
    public bool EnableDebugLog = true;
    public float DayMainLightStrength = 1f;
    public float NightMainLightStrength;
    public float DayEmissionIntensity;
    public float NightEmissionIntensity = 1f;
    public Color DaySkyColor = Color.white;
    public Color DayEquatorColor = Color.white;
    public Color DayGroundColor = Color.white;
    public Color NightSkyColor = Color.black;
    public Color NightEquatorColor = Color.black;
    public Color NightGroundColor = Color.black;
    public Material[] AmbientMaterials;

    private bool orbitPulseActive;
    private int orbitPulseCycleCount;
    private float? orbitPulseTargetReverseBlend;

    public void ResetToBase()
    {
        orbitPulseActive = false;
        orbitPulseTargetReverseBlend = null;
        StopOrbitPulseAudio();

        Material material = GetActiveSkyMaterial();
        if (material == null)
        {
            return;
        }

        float reverseBlend = GetMaterialFloat(material, "_ReverseBlend", 0f);
        ApplySkyPulse(reverseBlend, 0f);
        ApplyEnvironmentBlend(ResolveNightBlend01(reverseBlend, 0f));
    }

    public void BeginOrbitFx(float totalDuration)
    {
        orbitPulseActive = totalDuration > 0f;

        Material material = GetActiveSkyMaterial();
        if (material != null)
        {
            float currentReverseBlend = GetMaterialFloat(material, "_ReverseBlend", 0f);
            orbitPulseTargetReverseBlend = orbitPulseCycleCount > 0 ? (currentReverseBlend > 0.5f ? 0f : 1f) : currentReverseBlend;
            ApplySkyPulse(orbitPulseTargetReverseBlend.Value, 0f);
            ApplyEnvironmentBlend(ResolveNightBlend01(orbitPulseTargetReverseBlend.Value, 0f));
        }

        if (OrbitPulseParticle != null)
        {
            if (OrbitPulseParticle.isPlaying)
            {
                OrbitPulseParticle.Stop();
                OrbitPulseParticle.Clear();
            }
            OrbitPulseParticle.Play();
        }

        PlayOrbitPulseAudio();

        if (EnableEnvironmentSwitch)
        {
            Log("EnableEnvironmentSwitch is true, but custom environment switching remains intentionally isolated.");
        }
    }

    public void TickOrbitFx(float deltaTime, float progress01)
    {
        if (!orbitPulseActive)
        {
            return;
        }

        Material material = GetActiveSkyMaterial();
        if (material == null)
        {
            return;
        }

        if (!orbitPulseTargetReverseBlend.HasValue)
        {
            orbitPulseTargetReverseBlend = GetMaterialFloat(material, "_ReverseBlend", 0f);
        }

        float reverseBlend = orbitPulseTargetReverseBlend.Value;
        float pulseProgress = Mathf.Clamp01(progress01);
        ApplySkyPulse(reverseBlend, pulseProgress);
        ApplyEnvironmentBlend(ResolveNightBlend01(reverseBlend, pulseProgress));
    }

    public void CompleteOrbitFx()
    {
        if (!orbitPulseActive)
        {
            return;
        }

        orbitPulseActive = false;
        orbitPulseCycleCount++;
    }

    public float GetOrbitNightBlend01(float progress01)
    {
        float reverseBlend;
        if (orbitPulseTargetReverseBlend.HasValue)
        {
            reverseBlend = orbitPulseTargetReverseBlend.Value;
        }
        else
        {
            Material material = GetActiveSkyMaterial();
            reverseBlend = material != null ? GetMaterialFloat(material, "_ReverseBlend", 0f) : 0f;
        }

        return ResolveNightBlend01(reverseBlend, progress01);
    }

    public float GetCurrentNightBlend01()
    {
        Material material = GetActiveSkyMaterial();
        if (material == null)
        {
            return 0f;
        }

        return ResolveNightBlend01(
            GetMaterialFloat(material, "_ReverseBlend", 0f),
            GetMaterialFloat(material, "_PulseProgress", 0f));
    }

    private Material GetActiveSkyMaterial()
    {
        return SkyMaterial;
    }

    private void ApplySkyPulse(float reverseBlend, float pulseProgress)
    {
        Material material = GetActiveSkyMaterial();
        if (material == null)
        {
            return;
        }

        if (material.HasProperty("_ReverseBlend"))
        {
            material.SetFloat("_ReverseBlend", reverseBlend);
        }
        if (material.HasProperty("_PulseProgress"))
        {
            material.SetFloat("_PulseProgress", pulseProgress);
        }
    }

    private void ApplyEnvironmentBlend(float nightBlend01)
    {
        if (DirectionalLight != null)
        {
            DirectionalLight.intensity = Mathf.Lerp(DayMainLightStrength, NightMainLightStrength, nightBlend01);
        }

        Shader.SetGlobalFloat("_EmissionIntensity", Mathf.Lerp(DayEmissionIntensity, NightEmissionIntensity, nightBlend01));

        Color skyColor = Color.Lerp(DaySkyColor, NightSkyColor, nightBlend01);
        Color equatorColor = Color.Lerp(DayEquatorColor, NightEquatorColor, nightBlend01);
        Color groundColor = Color.Lerp(DayGroundColor, NightGroundColor, nightBlend01);

        RenderSettings.ambientSkyColor = skyColor;
        RenderSettings.ambientEquatorColor = equatorColor;
        RenderSettings.ambientGroundColor = groundColor;
        Shader.SetGlobalColor("_SkyColor", skyColor);
        Shader.SetGlobalColor("_EquatorColor", equatorColor);
        Shader.SetGlobalColor("_GroundColor", groundColor);

        if (AmbientMaterials == null)
        {
            return;
        }

        for (int i = 0; i < AmbientMaterials.Length; i++)
        {
            Material material = AmbientMaterials[i];
            if (material == null)
            {
                continue;
            }

            if (material.HasProperty("_SkyColor")) material.SetColor("_SkyColor", skyColor);
            if (material.HasProperty("_EquatorColor")) material.SetColor("_EquatorColor", equatorColor);
            if (material.HasProperty("_GroundColor")) material.SetColor("_GroundColor", groundColor);
        }
    }

    private AudioSource ResolveOrbitPulseAudio()
    {
        return OrbitPulseAudio != null ? OrbitPulseAudio : OrbitPulseAudioObject != null ? OrbitPulseAudioObject.GetComponent<AudioSource>() : null;
    }

    private void PlayOrbitPulseAudio()
    {
        if (!EnableOrbitPulseAudio)
        {
            return;
        }

        AudioSource audioSource = ResolveOrbitPulseAudio();
        if (audioSource == null)
        {
            return;
        }

        audioSource.enabled = true;
        audioSource.playOnAwake = false;
        audioSource.loop = false;
        audioSource.volume = Mathf.Clamp01(OrbitPulseAudioVolume);
        audioSource.Stop();
        audioSource.Play();
    }

    private void StopOrbitPulseAudio()
    {
        AudioSource audioSource = ResolveOrbitPulseAudio();
        if (audioSource != null)
        {
            audioSource.Stop();
        }
    }

    private static float ResolveNightBlend01(float reverseBlend, float pulseProgress)
    {
        float progress = Mathf.Clamp01(pulseProgress);
        return reverseBlend > 0.5f ? 1f - progress : progress;
    }

    private static float GetMaterialFloat(Material material, string propertyName, float fallback)
    {
        return material != null && material.HasProperty(propertyName) ? material.GetFloat(propertyName) : fallback;
    }

    private void Log(string message)
    {
        if (EnableDebugLog)
        {
            Debug.Log("[DouyinSequenceFxBridge] " + message, this);
        }
    }
}


