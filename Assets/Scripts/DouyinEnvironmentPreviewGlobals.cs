using UnityEngine;

[ExecuteAlways]
public sealed class DouyinEnvironmentPreviewGlobals : MonoBehaviour
{
    [Header("Blend")]
    [SerializeField] private bool readBlendFromSkyMaterial = true;
    [SerializeField] private Material skyMaterial;
    [Range(0f, 1f)]
    [SerializeField] private float nightBlend01;

    [Header("Emission")]
    [SerializeField] private float dayEmissionIntensity = 0f;
    [SerializeField] private float nightEmissionIntensity = 1f;

    [Header("Ambient Day")]
    [SerializeField] private Color daySkyColor = Color.white;
    [SerializeField] private Color dayEquatorColor = Color.white;
    [SerializeField] private Color dayGroundColor = Color.white;

    [Header("Ambient Night")]
    [SerializeField] private Color nightSkyColor = Color.black;
    [SerializeField] private Color nightEquatorColor = Color.black;
    [SerializeField] private Color nightGroundColor = Color.black;

    private void OnEnable()
    {
        Apply();
    }

    private void OnValidate()
    {
        Apply();
    }

    private void Update()
    {
        Apply();
    }

    [ContextMenu("Apply Preview Globals")]
    private void Apply()
    {
        float blend = ResolveNightBlend01();

        Shader.SetGlobalColor("_SkyColor", Color.Lerp(daySkyColor, nightSkyColor, blend));
        Shader.SetGlobalColor("_EquatorColor", Color.Lerp(dayEquatorColor, nightEquatorColor, blend));
        Shader.SetGlobalColor("_GroundColor", Color.Lerp(dayGroundColor, nightGroundColor, blend));
        Shader.SetGlobalFloat(
            "_EmissionIntensity",
            Mathf.Lerp(dayEmissionIntensity, nightEmissionIntensity, blend));
    }

    private float ResolveNightBlend01()
    {
        if (!readBlendFromSkyMaterial || skyMaterial == null)
        {
            return nightBlend01;
        }

        float reverseBlend = skyMaterial.HasProperty("_ReverseBlend") ? skyMaterial.GetFloat("_ReverseBlend") : 0f;
        float pulseProgress = skyMaterial.HasProperty("_PulseProgress") ? skyMaterial.GetFloat("_PulseProgress") : nightBlend01;
        pulseProgress = Mathf.Clamp01(pulseProgress);
        return reverseBlend > 0.5f ? 1f - pulseProgress : pulseProgress;
    }
}
