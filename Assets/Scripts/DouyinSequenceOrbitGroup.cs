using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public sealed class DouyinSequenceOrbitGroup : DouyinSequenceGroupBase
{
    public int PrimaryUnitIndex = 1;

    protected override Type UnitType => typeof(DouyinSequenceOrbitUnit);
    protected override string DefaultUnitScriptName => "DouyinSequenceOrbitUnit";

    protected override void Awake()
    {
        PrimaryUnitIndex = Mathf.Max(1, PrimaryUnitIndex);
        base.Awake();
    }

    public override void BeginBackward()
    {
        BeginForward();
    }

    public float GetSpeedFactor()
    {
        DouyinSequenceOrbitUnit primary = GetPrimaryUnit();
        return primary != null ? primary.GetSpeedFactor() : 0f;
    }

    public float GetProgress01()
    {
        DouyinSequenceOrbitUnit primary = GetPrimaryUnit();
        return primary != null ? primary.GetProgress01() : 0f;
    }

    public float GetTotalDuration()
    {
        DouyinSequenceOrbitUnit primary = GetPrimaryUnit();
        return primary != null ? primary.GetTotalDuration() : 0f;
    }

    private DouyinSequenceOrbitUnit GetPrimaryUnit()
    {
        if (units.Count == 0)
        {
            return null;
        }

        int index = PrimaryUnitIndex - 1;
        if (index < 0 || index >= units.Count)
        {
            index = 0;
        }
        return units[index] as DouyinSequenceOrbitUnit;
    }
}

