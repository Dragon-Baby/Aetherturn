using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceGearGroup : DouyinSequenceGroupBase
{
    public float MinSpeedFactor = 0.1f;

    protected override Type UnitType => typeof(DouyinSequenceGearUnit);
    protected override string DefaultUnitScriptName => "DouyinSequenceGearUnit";

    public void Tick(float deltaTime, float? driveFactor)
    {
        float minFactor = Mathf.Clamp01(MinSpeedFactor);
        float finalFactor = minFactor + (1f - minFactor) * Mathf.Clamp01(driveFactor ?? 0f);
        for (int i = 0; i < units.Count; i++)
        {
            if (units[i] is DouyinSequenceGearUnit gear)
            {
                gear.Tick(deltaTime, finalFactor);
            }
            else
            {
                units[i].Tick(deltaTime);
            }
        }
    }

    public override void Tick(float deltaTime)
    {
        Tick(deltaTime, null);
    }
}

